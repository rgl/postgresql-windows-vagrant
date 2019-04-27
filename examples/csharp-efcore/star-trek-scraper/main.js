"use strict";

const CHARACTERS_URL = "http://memory-alpha.wikia.com/wiki/Main_characters";

const puppeteer = require("puppeteer");
const https = require("https");
const { URL } = require("url");
const fs = require("fs");

async function getCharacters(page, url) {
    console.log("scraping", url);

    await page.goto(url);

    const characters = await page.evaluate(() => {
        var data = [];
        for (const li of document.querySelectorAll("#mw-content-text li")) {
            if (!li.innerText.match(/.+ as .+/)) {
                continue
            }
            const anchors = li.querySelectorAll("a");
            if (anchors.length < 2) {
                continue;
            }
            for (var el = li.parentNode.previousSibling; el; el = el.previousSibling) {
                if (el.nodeName === "H2") {
                    data.push({
                        name: anchors[1].innerText,
                        url: anchors[1].getAttribute("href"),
                        series: el.querySelector(".mw-headline").innerText.trim(),
                    });
                    break;
                }
            }
        }
        return data;
    });

    characters.forEach(c => c.url = (new URL(c.url, CHARACTERS_URL)).toString());

    return characters;
}

async function getCharacter(page, url) {
    console.log("scraping", url);

    await page.goto(url);

    const data = await page.evaluate(url => {
        var data = {
            url: url,
            name: document.querySelector("h1.page-header__title").innerText,
            gender: null,
            species: null,
            photoUrl: document.querySelector("#mw-content-text aside.portable-infobox figure img").src,
        };
        const infoBoxEl = document.querySelector("#mw-content-text aside.portable-infobox");
        for (const dataEl of infoBoxEl.querySelectorAll(".pi-data")) {
            const label = dataEl.querySelector(".pi-data-label").innerText;
            switch (label) {
                case "Gender:":
                    data.gender = dataEl.querySelector(".pi-data-value").innerText.toLowerCase();
                    break;
                case "Species:":
                    data.species = dataEl.querySelector(".pi-data-value").innerText;
                    break;
            }
        }
        return data;
    }, url);

    return {
        url: data.url,
        name: data.name,
        gender: data.gender,
        species: data.species,
        photo: (await downloadPhoto(data.photoUrl)).toString("base64"),
    };
}

function downloadPhoto(url) {
    return new Promise((resolve, reject) => {
        console.log("downloading photo from", url);
        https.get(
            url,
            response => {
                if (response.statusCode != 200) {
                    reject(new Error("Unexpected statusCode " + response.statusCode));
                }
                const contentType = response.headers["content-type"];
                if (contentType.indexOf("image/")) {
                    reject(new Error("Unexpected contentType " + contentType));
                }
                var photo = Buffer.from([]);
                response
                    .on("data", chunk => photo = Buffer.concat([photo, chunk]))
                    .on("end", () => resolve(photo));
            }
        );
    });
}

async function main() {
    console.log("launching...");
    const browser = await puppeteer.launch({
        headless: true,
        dumpio: false,
    });
    try {
        console.log("getting the browser version...");
        console.log("running under", await browser.version());

        console.log("creating a new browser page...");
        const page = await browser.newPage();

        console.log("lowering the needed bandwidth to scrape the site...");
        await page.setRequestInterception(true);
        page.on(
            "request",
            request => {
                if (request.resourceType() === "document") {
                    request.continue();
                } else {
                    request.abort();
                }
            }
        );

        const characters = await getCharacters(page, CHARACTERS_URL);

        const data = {};
        characters.forEach(c => data[c.series] = []);

        for (const c of characters) {
            const character = await getCharacter(page, c.url);
            data[c.series].push(character);
        }

        console.log("saving to data.json");
        fs.writeFileSync("data.json", JSON.stringify(data, null, 4));
    } finally {
        await browser.close();
    }
}

main();
