import http from 'http';

function post(path: string, body: any): Promise<{ status: number; text: string }>{
  return new Promise((resolve, reject) => {
    const req = http.request({ hostname: 'localhost', port: 3000, path, method: 'POST', headers: { 'Content-Type': 'application/json' }}, (res) => {
      let data = '';
      res.on('data', (c) => (data += c));
      res.on('end', () => resolve({ status: res.statusCode || 0, text: data }));
    });
    req.on('error', reject);
    req.write(JSON.stringify(body));
    req.end();
  });
}

test('sequential-thoughts returns summary', async () => {
  const res = await post('/sequential-thoughts', { thoughts: [ { kind: 'goal', content: 'test' } ] });
  expect(res.status).toBe(200);
  expect(res.text).toContain('goal:1');
});