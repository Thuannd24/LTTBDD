const https = require('https')

https.get('https://oauth2.googleapis.com/token', (res) => {
  console.log('statusCode:', res.statusCode)
}).on('error', (e) => {
  console.error('🔥 Request failed:', e.message)
})