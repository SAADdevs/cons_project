// agora.controller.js
const Agora = require('agora-access-token');

const generateToken = (req, res) => {
  const { channelName, userId } = req.body;
  const appId = process.env.AGORA_APP_ID;
  const appCertificate = process.env.AGORA_APP_CERTIFICATE;
  
  const expirationTime = 3600; // 1 hour
  const role = 1; // 1 for publisher, 2 for subscriber

  const token = new Agora.RtcTokenBuilder()
    .buildTokenWithUid(appId, appCertificate, channelName, userId, role, expirationTime);

  res.json({ token });
};

module.exports = { generateToken };