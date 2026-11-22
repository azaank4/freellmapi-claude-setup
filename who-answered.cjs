// Shows which real model answered each request the gateway served (read-only).
const path = require('node:path');
const { createRequire } = require('node:module');
const serverDir = path.join(__dirname, 'freellmapi', 'server');
const req = createRequire(path.join(serverDir, 'package.json'));
const Database = req('better-sqlite3');
const db = new Database(path.join(serverDir, 'data', 'freeapi.db'), { readonly: true, fileMustExist: true });
const rows = db.prepare("SELECT datetime(created_at,'localtime') AS time, platform AS provider, model_id AS real_model, status, substr(client_user_agent,1,28) AS client FROM requests ORDER BY id DESC LIMIT 15").all();
console.log('Last 15 requests the gateway served (real_model = the model that actually answered):');
console.table(rows);
const cc = db.prepare("SELECT count(*) c FROM requests WHERE client_user_agent LIKE '%claude-cli%' OR client_user_agent LIKE '%claude-code%'").get().c;
console.log(cc > 0 ? ('Claude Code requests seen by gateway: ' + cc + '  => FreeLLMAPI IS answering.') : 'Claude Code requests seen by gateway: 0  => nothing from Claude Code has used FreeLLMAPI yet.');
