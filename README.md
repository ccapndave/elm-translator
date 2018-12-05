# elm-translator

This is package to provide type safe internationalisation, where translations can be loaded at
runtime.  Default translations, substitutions and pluralisation are supported.


## Translations

Translations are usually loaded at runtime from a JSON file.

### Substitutions

Substitutions are implemented by surrounding the literal in braces:

```
{
  "MyNameIs": "Je m'appelle {name}"
}
```

### Pluralisation

Pluralisation is implemented by having the singular case on the left of the pipe symbol, and all
other cases on the right.  The number is be substituted using `{count}`.

```
{
  "MyAge": "I am only one year old|I'm {count} years old"
}
```


## Code generation

`elm-translator` is also an npm package containing a single binary `elm-translator`
which can be used to automatically generate the required Elm code to allow for type-safe
translation based on a JSON specification.  This same JSON specification can be used
to create the JSON translation file, and check that existing translation files aren't
missing any translations (to be implemented).

This is an example specification file.

```json
{
  "hello": {},
  "login": {
    "default": "Please login"
  },
  "welcomeMessage": {
    "substitutions": [
      "name"
    ],
    "default": "Hello {name}"
  },
  "ageMessage": {
    "pluralise": true,
    "substitutions": [
      "name"
    ],
    "default": "{name} is just one|{name} is {count} years old"
  }
}
```

In order to generate an Elm `Literals` module, you would use:

`npx elm-translator -f myspec.json`
