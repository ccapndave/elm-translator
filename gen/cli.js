#!/usr/bin/env node

const yargs = require("yargs");
const ejs = require("ejs");
const fs = require("fs");
const path = require("path");
const { execSync } = require("child_process");

function generate(spec) {
  const templatePath = path.resolve(__dirname, "templates", "Literals.elm.ejs");

  const lowerCaseFirstLetter = str => str.substr(0, 1).toLowerCase() + str.substr(1);

  const source = fs.readFileSync(templatePath, "utf8");
  const rendered = ejs.render(source, { spec, lowerCaseFirstLetter });

  try {
    const formatted = execSync(path.resolve(__dirname, "..", "node_modules", ".bin", "elm-format --stdin"), { input: rendered }).toString();
    return formatted;
  } catch (err) {
    console.error(err.toString());
    console.error("---");
    console.error(rendered);
  }
}

const argv = yargs
  .version(require(path.resolve(__dirname, "..", "package.json")).version)
  .usage("Usage: elm-translator <command> [options]")
  .help("h").alias("h", "help")
  .command("generate", "Generate an Elm literals module from the specification", yargs => {
    yargs
      .option("f", {
        describe: "The specification file to use"
      })
      .demandOption([ "f" ])
      .option("modulename", {
        default: "Literals",
        describe: "The name of the Elm module that will be generated"
      })
    }, ({ f, modulename }) => {
      if (!fs.existsSync(f)) {
        console.error(`The specification file ${f} doesn't exist.`);
      } else {
        const jsonStr = fs.readFileSync(f, "utf8");
        const json = JSON.parse(jsonStr);
        const result = generate(json);

        if (result) {
          console.log(result);
        }
      }
    }
  )
  .argv;
