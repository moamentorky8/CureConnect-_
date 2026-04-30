from firebase_functions import https_fn
from firebase_admin import initialize_app, db
from flask import Flask, request, jsonify
import requests
import os

# تهيئة Firebase
initialize_app()
app = Flask(__name__)

@app.route("/sos", methods=["POST"])
def trigger_sos():
    try:
        data = request.json
        uid = data.get("uid", "unknown_user")
        patient_name = data.get("name", "المريض")

        # 1. تحديث حالة الطوارئ في Firebase Realtime Database
        # ده اللي هيخلي الـ ESP32 أو الأبلكيشن عند المرافق ينور أو يدي إنذار
        ref = db.reference(f'users/{uid}/device_snapshot')
        ref.update({"emergency_status": True, "last_sos": {".sv": "timestamp"}})

        # 2. تشغيل صوت ElevenLabs (تحويل النص لكلام)
        # استبدل YOUR_KEY و VOICE_ID بالمفاتيح الخاصة بك
        api_key = "YOUR_ELEVEN_LABS_KEY"
        voice_id = "YOUR_VOICE_ID"
        url = f"https://api.elevenlabs.io/v1/text-to-speech/{voice_id}"
        
        headers = {"xi-api-key": api_key}
        payload = {
            "text": f"تنبيه طوارئ! {patient_name} يحتاج إلى المساعدة فوراً.",
            "model_id": "eleven_multilingual_v2"
        }
        
        # إرسال الطلب لـ ElevenLabs
        requests.post(url, json=payload, headers=headers)

        return jsonify({"status": "success", "message": "Alert triggered effectively"}), 200
    except Exception as e:
        return jsonify({"status": "error", "message": str(e)}), 500

# تحويل Flask App لـ Cloud Function
@https_fn.on_request()
def cureconnect_api(req: https_fn.Request) -> https_fn.Response:
    with app.request_context(req.environ):
        return app.full_dispatch_request()
