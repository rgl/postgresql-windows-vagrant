"use strict";

const CHARACTERS_URL = "http://memory-alpha.wikia.com/wiki/Main_characters";

const puppeteer = require("puppeteer");
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

    return await page.evaluate(url => {
        var data = {
            url: url,
            name: document.querySelector("h1.page-header__title").innerText,
            gender: null,
            species: null,
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
}

async function main() {
    const browser = await puppeteer.launch();
    try {
        const page = await browser.newPage();

        console.log("running under", await browser.version());

        // lower the needed bandwidth to scrape the site.
        await page.setRequestInterception(true);
        page.on(
            "request",
            request => {
                if (request.resourceType === "document") {
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
