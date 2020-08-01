import express from 'express';
import cors from 'cors';
import routes from './routes';
import { isAuthenticated } from './auth';
import { CORS_WHITELIST, LOGIN_WHITELIST_URL, NO_LOG_URL } from './config';
import { alarmclockInterval } from './routes/alarmclock/interval';
import { watermixerInterval } from './routes/watermixer/interval';
import { saveRequestToDb } from './firebase';
import { getIpStr, getCountryStr } from './helpers';
import morgan from 'morgan';
import chalk from 'chalk';

const app = express();
app.use(cors({ origin: CORS_WHITELIST }));
morgan.token('code', (req: express.Request, res: express.Response) => {
  const code = res.statusCode;
  if (code === 401 || code === 403) {
    return chalk.red.bold(code);
  } else {
    return chalk.green.bold(code);
  }
});

morgan.token('country', (req: express.Request, _) => {
  const country = getCountryStr(getIpStr(req));
  if (country === 'unknown') {
    return chalk.gray.bold(country);
  } else {
    return chalk.magentaBright.blue.bold(country);
  }
});

morgan.token('ip', (req: express.Request, _) => {
  return chalk.cyan.bold(getIpStr(req));
});

app.use(
  morgan((tokens, req, res) => {
    return [
      chalk.cyan(tokens.method(req, res)),
      chalk.cyan(tokens.url(req, res)),
      tokens.code(req, res),
      chalk.dim('-'),
      chalk.dim.bold(tokens['response-time'](req, res)),
      chalk.dim.bold('ms'),
      chalk.dim('-'),
      tokens.ip(req, res),
      chalk.dim('-'),
      chalk.gray.bold(tokens.country(req, res)),
    ].join(' ');
  }),
);
app.use(express.json()); // for parsing application/json

app.use((req, res, next): void => {
  // logRequest(req, res);
  if (!NO_LOG_URL.includes(req.url)) {
    const ip = getIpStr(req);
    saveRequestToDb({
      user: String(req.get('username')),
      requestPath: req.path,
      unixTime: new Date().getTime(),
      ip,
      userAgent: String(req.get('user-agent')),
      country: getCountryStr(ip),
    });
  }
  if (LOGIN_WHITELIST_URL.includes(req.url)) {
    next();
    return;
  }
  isAuthenticated(req, res, next);
});
app.use(
  (
    err: { message: string },
    req: express.Request,
    res: express.Response,
    // eslint-disable-next-line @typescript-eslint/no-unused-vars
    _next: express.NextFunction,
  ): void => {
    res.status(401).send(err.message);
  },
);

app.use('/', routes);

console.log('\x1b[36m%s\x1b[0m', 'Starting IoT data fetch interval');
setInterval(alarmclockInterval, 500);
setInterval(watermixerInterval, 500);

export default app;