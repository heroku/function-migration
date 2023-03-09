import oauth2 from 'salesforce-oauth2';
import got from 'got';

const callbackUrl = 'http://localhost:300/oauth/callback',
      consumerKey = '3MVG9AOp4kbriZOKr0ySjr6jBQ_gu5VO6KbnGNIaS7izf2J38nUmgefWkj3fmvqUZLbkR29yP0wf16w67M1He',
      consumerSecret = 'D46020171B8E5CC6CACF28CF666E66692E012F4DE0BF332FF12AB30BC8D7DD64';

async function activateSessionPermSet(access_token) {
  try {
    const options = {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${access_token}`
      },
      json: {
        inputs: [
            {
            PermSetName: "Functions"
            }
        ]
      },
    };
    const response = await got('https://cwall-wsl5:6101/services/data/v58.0/actions/standard/activateSessionPermSet', options).json();
    console.log(response.body.url);
    console.log(response.body.explanation);
    if (response.statusCode !== 200) {
      throw new Error(`Session Permset Activation failed [${response.statusCode}]: ${JSON.stringify(response.body)}`);
    } else {
      console.log(`Activiated Session Permset: ${JSON.stringify(response.body)}`);
    }
  } catch (error) {
    console.log(response.body);
  }
}

module.exports = async function (fastify, opts) {
  fastify.get('/', async function (request, reply) {
    const uri = oauth2.getAuthorizationUrl({
        redirect_uri: callbackUrl,
        client_id: consumerKey,
        scope: 'id api web refresh_token',
        base_url: 'https://cwall-wsl5:6101'
    });
    return reply.redirect(uri);
  })

  fastify.get('/oauth/callback', async function (request, reply) {
    const authorizationCode = request.param('code'); 
    oauth2.authenticate({
        redirect_uri: callbackUrl,
        client_id: consumerKey,
        client_secret: consumerSecret,
        code: authorizationCode,
        base_url: 'https://cwall-wsl5:6101'
    }, async function(error, payload) {
      await activateSessionPermSet(payload.access_token);
    });
  })
}
