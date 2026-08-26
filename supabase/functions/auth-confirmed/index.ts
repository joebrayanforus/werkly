import "jsr:@supabase/functions-js/edge-runtime.d.ts";

type ConfirmationCopy = {
  title: string;
  lines: [string, string];
  hint: string;
  footer: string;
};

const copies: Record<string, ConfirmationCopy> = {
  fr: {
    title: "Ton e-mail est confirmé.",
    lines: [
      "Ton compte Werkly est prêt.",
      "Ferme cette page, retourne dans l’application et connecte-toi.",
    ],
    hint: "La confirmation a bien été enregistrée en ligne.",
    footer: "Ton job étudiant, mieux ciblé.",
  },
  de: {
    title: "Deine E-Mail ist bestätigt.",
    lines: [
      "Dein Werkly-Konto ist bereit.",
      "Schließe diese Seite, kehre zur App zurück und melde dich an.",
    ],
    hint: "Die Bestätigung wurde sicher online gespeichert.",
    footer: "Dein Studentenjob, besser abgestimmt.",
  },
  en: {
    title: "Your email is confirmed.",
    lines: [
      "Your Werkly account is ready.",
      "Close this page, return to the app and sign in.",
    ],
    hint: "Your confirmation was securely saved online.",
    footer: "Your student job, better matched.",
  },
};

function escapeXml(value: string): string {
  return value
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;")
    .replaceAll("'", "&apos;");
}

function confirmationSvg(copy: ConfirmationCopy): string {
  const title = escapeXml(copy.title);
  const firstLine = escapeXml(copy.lines[0]);
  const secondLine = escapeXml(copy.lines[1]);
  const hint = escapeXml(copy.hint);
  const footer = escapeXml(copy.footer);

  return `<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1080 1500" role="img" aria-labelledby="title description">
  <title id="title">${title}</title>
  <desc id="description">${firstLine} ${secondLine}</desc>
  <defs>
    <radialGradient id="mint" cx="0" cy="0" r="1" gradientTransform="translate(190 150) rotate(40) scale(620 520)" gradientUnits="userSpaceOnUse">
      <stop stop-color="#DDEEE5"/>
      <stop offset="1" stop-color="#F7F7F2" stop-opacity="0"/>
    </radialGradient>
    <radialGradient id="warm" cx="0" cy="0" r="1" gradientTransform="translate(920 1330) rotate(-135) scale(520 500)" gradientUnits="userSpaceOnUse">
      <stop stop-color="#FFF0D9"/>
      <stop offset="1" stop-color="#F7F7F2" stop-opacity="0"/>
    </radialGradient>
    <filter id="shadow" x="90" y="170" width="900" height="1160" filterUnits="userSpaceOnUse">
      <feDropShadow dx="0" dy="26" stdDeviation="34" flood-color="#17231F" flood-opacity="0.13"/>
    </filter>
  </defs>
  <rect width="1080" height="1500" fill="#F7F7F2"/>
  <rect width="1080" height="1500" fill="url(#mint)"/>
  <rect width="1080" height="1500" fill="url(#warm)"/>
  <g filter="url(#shadow)">
    <rect x="120" y="210" width="840" height="1040" rx="54" fill="#FFFFFF" stroke="#E3E8E1" stroke-width="3"/>
  </g>
  <rect x="190" y="290" width="86" height="86" rx="26" fill="#E9A95B"/>
  <text x="233" y="352" text-anchor="middle" fill="#17231F" font-family="Arial, sans-serif" font-size="48" font-weight="900">W</text>
  <text x="300" y="352" fill="#17231F" font-family="Arial, sans-serif" font-size="49" font-weight="900">werkly</text>
  <circle cx="260" cy="560" r="76" fill="#DDEEE5"/>
  <path d="M224 560l24 25 52-58" fill="none" stroke="#2F6B55" stroke-width="18" stroke-linecap="round" stroke-linejoin="round"/>
  <text x="190" y="735" fill="#17231F" font-family="Arial, sans-serif" font-size="62" font-weight="900" letter-spacing="-1.5">${title}</text>
  <text x="190" y="840" fill="#607069" font-family="Arial, sans-serif" font-size="34">${firstLine}</text>
  <text x="190" y="900" fill="#607069" font-family="Arial, sans-serif" font-size="30">${secondLine}</text>
  <rect x="190" y="985" width="700" height="122" rx="28" fill="#F1F6F2"/>
  <circle cx="238" cy="1046" r="17" fill="#2F6B55"/>
  <path d="M230 1046l6 7 12-15" fill="none" stroke="#FFFFFF" stroke-width="5" stroke-linecap="round" stroke-linejoin="round"/>
  <text x="275" y="1058" fill="#355247" font-family="Arial, sans-serif" font-size="26">${hint}</text>
  <text x="190" y="1182" fill="#87938E" font-family="Arial, sans-serif" font-size="24">Werkly · ${footer}</text>
</svg>`;
}

Deno.serve((request: Request) => {
  if (request.method !== "GET" && request.method !== "HEAD") {
    return new Response("Method not allowed", {
      status: 405,
      headers: { Allow: "GET, HEAD" },
    });
  }

  const requestedLanguage = new URL(request.url).searchParams.get("lang")
    ?.toLowerCase();
  const browserLanguage = request.headers.get("accept-language")
    ?.slice(0, 2)
    .toLowerCase();
  const language = requestedLanguage && copies[requestedLanguage]
    ? requestedLanguage
    : browserLanguage && copies[browserLanguage]
    ? browserLanguage
    : "en";
  const body = confirmationSvg(copies[language]);

  return new Response(request.method === "HEAD" ? null : body, {
    headers: {
      "Content-Type": "image/svg+xml; charset=utf-8",
      "Cache-Control": "no-store",
      "Content-Security-Policy":
        "default-src 'none'; style-src 'none'; script-src 'none'; frame-ancestors 'none'",
      "Referrer-Policy": "no-referrer",
      "X-Content-Type-Options": "nosniff",
      "X-Frame-Options": "DENY",
    },
  });
});
