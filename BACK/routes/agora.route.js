// agora.route.js
const Agora = require('agora-access-token');

router.post('/generate-token', (req, res) => {
  const { channelName, userId } = req.body;
  
  const appId = process.env.AGORA_APP_ID;
  const appCertificate = process.env.AGORA_APP_CERTIFICATE;
  const expirationTime = 3600; // 1 hour

  const token = new Agora.RtcTokenBuilder()
    .buildTokenWithUid(appId, appCertificate, channelName, userId, 1, expirationTime);

  res.json({ token });
});