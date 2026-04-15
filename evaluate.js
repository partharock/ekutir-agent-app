const WebSocket = require('ws');
const ws = new WebSocket('ws://localhost:57487/devtools/page/0C4DA828C255D425015C3E61FFAF84AB');

ws.on('open', function open() {
  ws.send(JSON.stringify({
    id: 1,
    method: 'Runtime.evaluate',
    params: {
      expression: 'Object.keys(window).filter(k => k.toLowerCase().includes("mappls") || k.toLowerCase().includes("mapmyindia") || k.toLowerCase().includes("map"))'
    }
  }));
});

ws.on('message', function incoming(data) {
  console.log(data);
  process.exit(0);
});
