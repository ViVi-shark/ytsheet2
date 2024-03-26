{
    const nameNode = document.querySelector('.name-taxa h1').cloneNode(true);
    nameNode.querySelector('small')?.remove();
    const monsterName = nameNode.textContent.trim();

    const lootSection = document.querySelector('section.loots');

    if (lootSection != null) {
        function normalizeNumber(text) {
            return text
                .replaceAll('０', '0')
                .replaceAll('１', '1')
                .replaceAll('２', '2')
                .replaceAll('３', '3')
                .replaceAll('４', '4')
                .replaceAll('５', '5')
                .replaceAll('６', '6')
                .replaceAll('７', '7')
                .replaceAll('８', '8')
                .replaceAll('９', '9');
        }

        /** @var {Array<{min?: int|null, max?: int|null, content: string}>} */
        const rows = [];

        /** @var {{min?: int|null, max?: int|null}|null} */
        let lastRange = null;
        for (const node of lootSection.querySelectorAll('dl > :is(dt, dd)')) {
            switch (node.nodeName) {
                case 'DT': {
                    const rangeText = normalizeNumber(node.textContent.trim());

                    if (rangeText.includes("自動")) {
                        lastRange = null;
                    } else if (rangeText.match(/^\d+$/)) {
                        const n = parseInt(rangeText);
                        lastRange = {min: n, max: n};
                    } else {
                        const m = rangeText.match(/^(\d+)?[-ー―－~～](\d+)?$/);

                        if (m == null) {
                            console.warn(`Unexpected format range: ${rangeText}`);
                            lastRange = null;
                            continue;
                        }

                        const min = m[1] != null ? parseInt(m[1]) : null;
                        const max = m[2] != null ? parseInt(m[2]) : null;
                        lastRange = {min, max};
                    }
                }
                    break;
                case 'DD':
                    if (lastRange == null) {
                        continue;
                    }

                    rows.push(
                        {
                            min: lastRange.min,
                            max: lastRange.max,
                            content: node.textContent.trim()
                        }
                    );
                    lastRange = null;
                    break;
            }
        }

        if (rows.length > 0) {
            const command =
                `/random-table ${monsterName}戦利品\n2d6 2 12\n` +
                rows
                    .map(x => `${x.min !== x.max ? `${x.min ?? ''}-${x.max ?? ''}` : x.min.toString()}\t${x.content}`)
                    .join('\n');

            const buttonToCopy = document.createElement('button');
            buttonToCopy.classList.add('to-copy');
            lootSection.appendChild(buttonToCopy);

            buttonToCopy.addEventListener(
                'click',
                () => navigator.clipboard.writeText(command)
            );
        }
    }
}
