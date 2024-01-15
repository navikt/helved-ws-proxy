WS Proxy
========

Skaper en forbindelse mellom GCP og SOAP-tjenester i FSS.

## Hvordan

Alle requests må ha JWT token som Bearer authentication for at ws-proxy skal slippe de gjennom.

Derfor må alle konsumenter være i accessPolicy-listen til ws-proxy.


### Gandalf

Klienter oppfordres til å bruke Gandalf for å få SAML-assertion fremfor den klassiske STS-en.
Fordi Gandalf også krever autentisering så må dette legges i `Proxy-Authorization`-headeren istedenfor.

```
curl \
  -H "Authorization: Bearer <jwt>" \
  -H "Proxy-Authorization: Basic <basic..>" \
  https://ws-proxy...fss-pub.nais.io/gandalf/rest/v1/sts/samltoken
```