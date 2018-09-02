const express = require('express');
const proxy = require('express-http-proxy');

const app = express();

app.use(host('ziting.wang', express.static('public/ziting.wang')));
app.use(host('jysperm.me', express.static('public/jysperm.me')));
app.use(host('atom-china.org', proxy('cn-forum.rpvhost.net:8443', {
  https: true,
  preserveHostHdr: true
})));

app.get('/', (req, res, next) => {
  res.json({ping: 'pong'});
});

app.use( (req, res, next) => {
  if (!res.headersSent) {
    if (req.matchedDomain == 'jysperm.me') {
      res.status(404).sendFile(`${__dirname}/public/${req.matchedDomain}/404/index.html`);
    } else if (req.matchedDomain) {
      res.sendStatus(404);
    } else {
      res.status(404).json({
        'error': 'no such website',
        'domain': req.hostname
      });
    }
  }
});

app.listen(process.env.LEANCLOUD_APP_PORT || 3000);

function host(domain, middleware) {
  return (req, res, next) => {
    if (req.hostname === domain) {
      req.matchedDomain = domain;
      middleware(req, res, next);
    } else {
      next();
    }
  };
}
