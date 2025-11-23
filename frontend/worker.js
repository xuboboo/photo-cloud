export default {
  async fetch(request, env, ctx) {
    try {
      const url = new URL(request.url);
      
      // Get the asset from ASSETS binding
      let response = await env.ASSETS.fetch(request);
      
      // If asset not found (404), serve index.html for SPA routing
      if (response.status === 404) {
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
      
      // Clone response to modify headers
      response = new Response(response.body, response);
      
      // Add cache control headers for HTML files
      if (url.pathname === '/' || url.pathname.endsWith('.html') || !url.pathname.includes('.')) {
        response.headers.set('Cache-Control', 'public, max-age=0, must-revalidate');
      } else {
        // Cache static assets for 1 year
        response.headers.set('Cache-Control', 'public, max-age=31536000, immutable');
      }
      
      return response;
    } catch (err) {
      return new Response('Internal Error: ' + err.toString(), { status: 500 });
    }
  }
};
