export default {
  async fetch(request, env, ctx) {
    try {
      // Get the asset from ASSETS binding
      let response = await env.ASSETS.fetch(request);
      
      // If asset not found (404), serve index.html for SPA routing
      if (response.status === 404) {
        const url = new URL(request.url);
        const pathname = url.pathname;
        
        // Only serve index.html if it's not a file request (no extension)
        if (!pathname.includes('.')) {
          // Create a new request for index.html
          const indexRequest = new Request(
            url.origin + '/index.html',
            request
          );
          response = await env.ASSETS.fetch(indexRequest);
        }
      }
      
      return response;
    } catch (err) {
      return new Response('Internal Error: ' + err.toString(), { status: 500 });
    }
  }
};
