# Kagi Translate helper.
#
# The token is the Kagi session cookie used by translate.kagi.com. By default
# it is read from $env.KAGI_SESSION_TOKEN; pass --token-env to use a different
# env var.
def translate [
   --from (-f): string = "auto"             # Source language code
   --to (-t): string = "en"                 # Target language code
   --model (-m): string = "standard"        # Kagi translation model
   --token-env: string = "KAGI_SESSION_TOKEN" # Env var holding the Kagi cookie
   ...text: string                          # Text to translate (joined with spaces)
]: nothing -> string {
   let text = ($text | str join " ")

   if ($text | is-empty) {
      error make {msg: "No text provided to translate."}
   }

   let token = ($env | get -o $token_env)

   if ($token | is-empty) {
      error make {msg: $"Missing Kagi token. Set the ($token_env) environment variable."}
   }

   let response = (
      http post
      --allow-errors
      --full
      --content-type "application/json"
      --headers {
         Cookie: $"kagi_session=($token)"
         Accept: "application/json"
      }
      "https://translate.kagi.com/api/translate"
      {
         text: $text
         from: $from
         to: $to
         model: $model
      }
   )

   if $response.status != 200 {
      error make {msg: $"Kagi translate request failed with status ($response.status):\n($response.body)"}
   }

   $response.body.translation? | default ($response.body | to text)
}
