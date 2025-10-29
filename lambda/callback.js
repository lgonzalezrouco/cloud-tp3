import axios from "axios";

export const handler = async (event) => {
  const requiredEnvVars = [
    "COGNITO_DOMAIN",
    "COGNITO_REGION",
    "CLIENT_ID",
    "CLIENT_SECRET",
    "REDIRECT_URI",
    "FRONTEND_URL",
  ];
  const missingVars = requiredEnvVars.filter(
    (varName) => !process.env[varName]
  );

  if (missingVars.length > 0) {
    console.error("Missing required environment variables:", missingVars);
    return {
      statusCode: 500,
      body: JSON.stringify({ error: "Server configuration error" }),
    };
  }

  if (!event.queryStringParameters || !event.queryStringParameters.code) {
    return {
      statusCode: 400,
      body: JSON.stringify({ error: "Missing authorization code" }),
    };
  }

  const { code } = event.queryStringParameters;

  const cognitoDomain = `https://${process.env.COGNITO_DOMAIN}`;
  const clientId = process.env.CLIENT_ID;
  const clientSecret = process.env.CLIENT_SECRET;
  const redirectUri = `${process.env.REDIRECT_URI}/callback`;
  const frontendUrl = process.env.FRONTEND_URL;

  try {
    const response = await axios.post(
      `${cognitoDomain}/oauth2/token`,
      new URLSearchParams({
        grant_type: "authorization_code",
        client_id: clientId,
        client_secret: clientSecret,
        redirect_uri: redirectUri,
        code: code,
      }),
      {
        headers: {
          "Content-Type": "application/x-www-form-urlencoded",
        },
      }
    );

    const { id_token, access_token, refresh_token } = response.data;

    const redirectUrl = `${frontendUrl}/#id_token=${id_token}&access_token=${access_token}&refresh_token=${refresh_token}`;

    return {
      statusCode: 302,
      headers: {
        Location: redirectUrl,
        "Cache-Control": "no-cache, no-store- must-revalidate",
        Pragma: "no-cache",
        Expires: "0",
      },
    };
  } catch (error) {
    console.error("Error al intercambiar el código por tokens:", error);

    if (error.response) {
      console.error("Cognito error:", error.response.data);
      return {
        statusCode: 400,
        body: JSON.stringify({
          error: "Invalid authorization code or configuration",
          details:
            error.response.data?.error_description || "Authentication failed",
        }),
      };
    } else if (error.request) {
      console.error("Network error:", error.message);
      return {
        statusCode: 503,
        body: JSON.stringify({ error: "Service temporarily unavailable" }),
      };
    } else {
      return {
        statusCode: 500,
        body: JSON.stringify({ error: "Internal server error" }),
      };
    }
  }
};
