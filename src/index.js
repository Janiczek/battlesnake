// https://github.com/battlesnakeio/starter-snake-node/blob/master/index.js
const bodyParser = require('body-parser');
const express = require('express');
const app = express();
const {
  fallbackHandler,
  notFoundHandler,
  genericErrorHandler,
  poweredByHandler
} = require('./handlers.js');

const {Elm} = require('../dist/elm.js');
const elmApp = Elm.Main.init();

// For deployment to Heroku, the port needs to be set using ENV, so
// we check for the port number in process.env
app.set('port', (process.env.PORT || 9001));

app.enable('verbose errors');

app.use(bodyParser.json());
app.use(poweredByHandler);

// --- SNAKE LOGIC GOES BELOW THIS LINE ---

app.post('/start', (request, response) => {

  const handler = (startResponse) => {
    elmApp.ports.startResponse.unsubscribe(handler);
    response.json(startResponse);
  };

  elmApp.ports.startResponse.subscribe(handler);
  elmApp.ports.startRequest.send(request.body);

});

app.post('/move', (request, response) => {

  const handler = (moveResponse) => {
    elmApp.ports.moveResponse.unsubscribe(handler);
    response.json(moveResponse);
  };

  elmApp.ports.moveResponse.subscribe(handler);
  elmApp.ports.moveRequest.send(request.body);

});

app.post('/end', (request, response) => {
  elmApp.ports.endRequest.send(request.body);
  return response.json({});
});

app.post('/ping', (request, response) => {
  return response.json({});
});

// --- SNAKE LOGIC GOES ABOVE THIS LINE ---

app.use('*', fallbackHandler);
app.use(notFoundHandler);
app.use(genericErrorHandler);

app.listen(app.get('port'), () => {
  console.log('Server listening on port %s', app.get('port'));
});
