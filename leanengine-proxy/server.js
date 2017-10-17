const express = require('express');
const proxy = require('express-http-proxy');

const app = express();

app.use(host('ziting.wang', express.static('public/ziting.wang')));
app.use(host('jysperm.me', express.static('public/jysperm.me')));
app.use(host('caipai.fm', express.static('public/caipai.fm')));
app.use(host('jybox.net', express.static('public/jybox.net')));
app.use(host('atom-china.org', proxy('140.143.189.132:49151')));

app.get('/', (req, res, next) => {
  res.json({ping: 'pong'});
});

app.use( (req, res, next) => {
  if (!res.headersSent) {
    res.status(404).json({
      'error': 'no such website',
      'domain': req.hostname
    });
  }
});

app.listen(process.env.LEANCLOUD_APP_PORT || 3000);

function host(domain, middleware) {
  return (req, res, next) => {
    if (req.hostname === domain) {
      middleware(req, res, next)
    } else {
      next();
    }
  };
}
