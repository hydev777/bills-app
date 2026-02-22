/**
 * Simple logger with level and timestamp. Use for app and request/error logging.
 */

const levels = { info: 'INFO', warn: 'WARN', error: 'ERROR', debug: 'DEBUG' };

function formatMessage(level, ...args) {
  const ts = new Date().toISOString();
  const prefix = `[${ts}] [${level}]`;
  return [prefix, ...args];
}

const logger = {
  info(...args) {
    console.log(...formatMessage(levels.info, ...args));
  },
  warn(...args) {
    console.warn(...formatMessage(levels.warn, ...args));
  },
  error(...args) {
    console.error(...formatMessage(levels.error, ...args));
  },
  debug(...args) {
    if (process.env.NODE_ENV === 'development') {
      console.log(...formatMessage(levels.debug, ...args));
    }
  },
};

/**
 * Sanitize headers for logging (hide full Authorization token).
 */
function sanitizeHeaders(headers) {
  const out = { ...headers };
  if (out.authorization) out.authorization = 'Bearer ***';
  return out;
}

/**
 * Express middleware: log every HTTP request (method, path, request body/headers, status, duration).
 */
function requestLogger(req, res, next) {
  const start = Date.now();
  const method = req.method;
  const path = req.originalUrl || req.url;

  res.on('finish', () => {
    const duration = Date.now() - start;
    const status = res.statusCode;
    const level = status >= 500 ? 'error' : status >= 400 ? 'warn' : 'info';
    logger[level](`${method} ${path} ${status} ${duration}ms`);
    logger[level]('  Route:', path);
    logger[level]('  Request headers:', sanitizeHeaders(req.headers));
    if (req.body && Object.keys(req.body).length > 0) {
      logger[level]('  Request body:', req.body);
    }
    if (req.query && Object.keys(req.query).length > 0) {
      logger[level]('  Query:', req.query);
    }
  });

  next();
}

module.exports = { logger, requestLogger };
