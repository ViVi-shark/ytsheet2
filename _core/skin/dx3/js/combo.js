// noinspection JSNonASCIINames,NonAsciiCharacters

(() => {
    const encroachFixed = document.getElementById('enc-bonus').classList.contains('encroach-fixed');

    function wrapByTag(text, tag) {
        return `<${tag}>${text}</${tag}>`;
    }

    function getWrapperByNodeName(node) {
        switch (node.nodeName) {
            case 'SPAN':
                if (node.classList.length === 0) {
                    return text => text;
                } else {
                    switch (node.classList[0]) {
                        case 'oblique':
                            return text => `<i>${text}</i>`;
                        case 'head-of-line':
                            return () => '';
                        case 'thinest':
                            return text => text;
                    }
                }
                break;
            case 'B':
                return text => `<b>${text}</b>`;
            case 'BR':
                return () => '\n';
            case 'RUBY':
                return text => wrapByTag(text, 'ruby');
            case 'RT':
                return text => `<rt>${text}`;
            case 'RP':
                return () => '';
        }
        console.log([node]);
        return text => text;
    }

    function nodeToText(node) {
        let text = '';
        node.childNodes.forEach(
            child => {
                if (child.nodeName === '#text') {
                    text += child.nodeValue;
                } else {
                    text += getWrapperByNodeName(child)(nodeToText(child));
                }
            }
        );
        return text;
    }

    function format侵蝕値(sourceText) {
        if (/^\s*[\-―－]?\s*$/.test(sourceText)) {
            return null;
        }

        const m = sourceText.match(/^\s*(\d+)\s*$/);
        if (m != null) {
            return ` @侵蝕+${m[1]} `;
        }

        return `侵蝕値：${sourceText}`;
    }

    function makePatternsText(難易度, patternsNode) {
        /**
         * @param {string} sourceCommand
         * @return {string}
         */
        function optimizeCommand(sourceCommand) {
            /**
             * @param {?string} expression
             * @return {?number}
             */
            function optimizeExpression(expression) {
                return eval(expression);
            }

            const m = sourceCommand.match(/^([\d+\-]+)dx([\d+\-]+)@([\d+\-]+)(>=([\d+\-]+))?/i);

            if (m == null) {
                return sourceCommand;
            }

            const diceCount = optimizeExpression(m[1]) ?? 0;
            const additiveValue = optimizeExpression(m[2]) ?? 0;
            const criticalThreshold = optimizeExpression(m[3]) ?? 10;
            const difficulty = optimizeExpression(m[5]);

            const optimizedCommand = `${diceCount}dx${additiveValue < 0 ? '' : '+'}${additiveValue}@${criticalThreshold}`;
            return difficulty == null ? optimizedCommand : `${optimizedCommand}>=${difficulty}`
        }

        function makePatternText(難易度, 条件, ダイス, Ｃ値, 修正, 攻撃力) {
            const 難易度_numeric = 難易度.match(/(\d+)/);

            const command = (() => {
                const command = ダイス != null && (!/^\s*(自動成功)?\s*$/.test(難易度) || Ｃ値 != null)
                    ? `${ダイス}${encroachFixed ? '' : '+{DB}'}dx${(修正 ?? '').substring(0, 1) === '-' ? '' : '+'}${修正 ?? 0}${encroachFixed ? '' : '+{AB}'}@${Ｃ値 ?? 10}${encroachFixed ? '' : '+{CB}'}${難易度_numeric != null ? `>=${難易度_numeric[1]}` : ''}`
                    : null;

                return command != null && encroachFixed ? optimizeCommand(command) : command;
            })();

            if (command == null && 攻撃力 == null) {
                return null;
            }

            if (条件 == null) {
                return [
                    command != null ? `判定： ${command}` : null,
                    攻撃力 != null ? `攻撃力：${['+', '-'].includes(攻撃力.substring(0, 1)) ? '' : '+'}${攻撃力}` : null,
                ]
                    .filter(x => x != null)
                    .join(' ，');
            }

            return '| ' + [
                条件,
                command,
                攻撃力 != null ? `${['+', '-'].includes(攻撃力.substring(0, 1)) ? '' : '+'}${攻撃力}` : null,
            ]
                .map(x => x != null ? wrapByTag(x, 'small') : '')
                .join(' | ') + ' |';
        }

        /** @var {Array<{条件?: ?string, ダイス?: ?string, Ｃ値?: ?string, 修正?: ?string, 攻撃力?: ?string}>} */
        const patterns = [];

        [
            ['combo-cond', '条件'],
            [
                'combo-dice',
                'ダイス',
                encroachFixed
                    ? (node, value) => {
                        const bonusDice = node.getAttribute('data-edb');

                        return bonusDice == null || bonusDice === ''
                            ? value
                            : `${value}+${bonusDice}`;
                    }
                    : null,
            ],
            ['combo-crit', 'Ｃ値'],
            ['combo-fixed', '修正'],
            ['combo-atk', '攻撃力'],
        ].forEach(
            x => {
                const [className, label, modifier] = x;

                patternsNode.querySelectorAll(`dd.${className}`).forEach(
                    (node, index) => {
                        const value = node.textContent;
                        if (/^\s*[\-―－]?\s*$/.test(value)) {
                            return;
                        }

                        while (index + 1 > patterns.length) {
                            patterns.push({});
                        }

                        patterns[index][label] = modifier != null ? modifier(node, value) : value;
                    }
                );
            }
        );

        const patternsText = patterns
            .map(x => makePatternText(難易度, x['条件'], x['ダイス'], x['Ｃ値'], x['修正'], x['攻撃力']))
            .filter(x => x != null)
            .join('\n');

        if (patternsText === '') {
            return null;
        }

        const has攻撃力 = patterns.some(x => x['攻撃力'] != null);

        const headerRow = '| ' + ['条件', '判定', has攻撃力 ? '攻撃力' : '']
            .filter(x => x !== '')
            .map(x => wrapByTag(x, 'small'))
            .join(' | ') + ' |';

        return (
            patterns.some(x => x.条件 != null && x.条件 !== '')
                ? headerRow + '\n'
                : ''
        ) + (has攻撃力 ? patternsText : patternsText.replaceAll(/\|\s+\|$/mg, '|'));
    }

    document.querySelectorAll('#combo .combo-table').forEach(
        comboNode => {

            const 名称 = nodeToText(comboNode.querySelector('h3'));
            const 組み合わせ = comboNode.querySelector('.combo-combo dd').textContent;
            const タイミング = comboNode.querySelector('.combo-in > dl:nth-child(1) > dd').textContent.replace(/^\s+/, '').replace(/\s+$/, '');
            const 難易度 = comboNode.querySelector('.combo-in > dl:nth-child(3) > dd').textContent.replace(/^\s+/, '').replace(/\s+$/, '');
            const 対象 = comboNode.querySelector('.combo-in > dl:nth-child(4) > dd').textContent;
            const 射程 = comboNode.querySelector('.combo-in > dl:nth-child(5) > dd').textContent;
            const 侵蝕値 = format侵蝕値(comboNode.querySelector('.combo-in > dl:nth-child(6) > dd').textContent);
            const 効果 = nodeToText(comboNode.querySelector('.combo-note')).split('\n').map(
                line => /^([~～]?\d+[%％]|\d+[~～](\d+)?[%％])/.test(line) ? '・' + wrapByTag(line, 'small') : line
            ).join('\n');

            const 構成 = 組み合わせ != null ? 組み合わせ : '構成：－';

            const パターン = makePatternsText(難易度, comboNode.querySelector('.combo-out'));

            const 対象_composed = [`「射程：${射程}」`, `「対象：${対象}」`].filter(x => !(/：」$/).test(x)).join('');
            const 効果_resolved =
                (
                    /^\s*[\-―－]?\s*$/.test(タイミング) || ['メジャー', 'メジャーアクション', 'オート', 'オートアクション'].includes(タイミング)
                        ? ''
                        : `${タイミング}。`
                ) + 効果.replace('対象', 対象_composed);

            const 全文 = [
                [
                    名称 != null && 名称 !== '' ? `〚${名称}〛` : null,
                    `${構成}${侵蝕値 != null ? wrapByTag(`（${侵蝕値}）`, 'small') : ''}`
                ]
                    .filter(x => x != null && x !== '')
                    .join('――'),
                wrapByTag(効果_resolved, 'small'),
                パターン,
            ]
                .filter(x => x != null && x !== '')
                .join('\n');

            const button = document.createElement('button');
            button.classList.add('to-copy');

            comboNode.querySelector('.combo-note').append(button);

            button.addEventListener('click', () => navigator.clipboard.writeText(全文));
        }
    );
})();
