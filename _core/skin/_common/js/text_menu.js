(function(document, window){
    const body = document.getElementsByTagName('body')[0];
    const textMenuClass = 'text-arrangement-menu';
    const textCommandClass = 'text-arrangement-command';

    function createMenu(element){
        const div = document.createElement('div');
        div.classList.add(textMenuClass);

        for (const [condition, commandName, operation] of [
            [
                ['INPUT', 'TEXTAREA'],
                '太字',
                function(s) {
                    return ['chars', '\'\'' + s + '\'\'', [2, -2]];
                }
            ],
            [
                ['INPUT', 'TEXTAREA'],
                '斜体',
                function(s) {
                    return ['chars', '\'\'\'' + s + '\'\'\'', [3, -3]];
                }
            ],
            [
                ['INPUT', 'TEXTAREA'],
                '打消線',
                function(s) {
                    return ['chars', '%%' + s + '%%', [2, -2]];
                }
            ],
            [
                ['INPUT', 'TEXTAREA'],
                '下線',
                function(s) {
                    return ['chars', '__' + s + '__', [2, -2]];
                }
            ],
            [
                ['INPUT', 'TEXTAREA'],
                '透明',
                function(s) {
                    return ['chars', '{{' + s + '}}', [2, -2]];
                }
            ],
            [
                ['INPUT', 'TEXTAREA'],
                'ルビ',
                function(s) {
                    return ['chars', '|' + s + '《》', [-1, -1]];
                }
            ],
            [
                ['INPUT', 'TEXTAREA'],
                '傍点',
                function(s) {
                    return ['chars', '《《' + s + '》》', [2, -2]];
                }
            ],
            [
                ['INPUT', 'TEXTAREA'],
                'リンク',
                function(s) {
                    return ['chars', '[[' + s + '>URL]]', [-5, -2]];
                }
            ],
            [
                ['INPUT', 'TEXTAREA'],
                '別シート',
                function(s) {
                    return ['chars', '[' + s + '#シートのID]', [-7, -1]];
                }
            ],
            [
                ['TEXTAREA'],
                '大見出し',
                function(_, lines) {
                    return ['lines', '* ' + lines, [2, 2 + lines.split('\n')[0].length + 1]];
                }
            ],
            [
                ['TEXTAREA'],
                '中見出し',
                function(_, lines) {
                    return ['lines', '** ' + lines, [3, 3 + lines.split('\n')[0].length + 1]];
                }
            ],
            [
                ['TEXTAREA'],
                '小見出し',
                function(_, lines) {
                    return ['lines', '*** ' + lines, [4, 4 + lines.split('\n')[0].length + 1]];
                }
            ],
            [
                ['TEXTAREA'],
                '以降左寄せ',
                function(_, lines) {
                    return ['lines', 'LEFT:\n' + lines, [6, 6]];
                }
            ],
            [
                ['TEXTAREA'],
                '以降中央寄せ',
                function(_, lines) {
                    return ['lines', 'CENTER:\n' + lines, [8, 8]];
                }
            ],
            [
                ['TEXTAREA'],
                '以降右寄せ',
                function(_, lines) {
                    return ['lines', 'RIGHT:\n' + lines, [7, 7]];
                }
            ],
            [
                ['TEXTAREA'],
                '横罫線（直線）',
                function(_, lines) {
                    return ['lines', '----\n' + lines, [5, 5]];
                }
            ],
            [
                ['TEXTAREA'],
                '横罫線（点線）',
                function(_, lines) {
                    return ['lines', ' * * * *\n' + lines, [9, 9]];
                }
            ],
            [
                ['TEXTAREA'],
                '横罫線（破線）',
                function(_, lines) {
                    return ['lines', ' - - - -\n' + lines, [9, 9]];
                }
            ],
            [
                ['TEXTAREA'],
                '折り畳み',
                function(_, lines) {
                    const a = lines.split('\n');
                    const r = '[>]' + a[0] + '\n' + a.slice(1).join('\n') + '\n[---]\n';
                    return [
                        'lines',
                        r,
                        [0, r.length]
                    ];
                }
            ],
            [
                ['TEXTAREA'],
                'コメントアウト',
                function(_, lines) {
                    if (lines.includes('\n')) {
                        const commented_out = lines.split('\n').map(
                            function(x){
                                return '//' + x;
                            }
                        ).join('\n');
                        return ['lines', commented_out, [0, commented_out.length]];
                    } else {
                        return ['lines', '//' + lines, [2, 2 + lines.length]];
                    }
                }
            ],
        ]) {
            if (!condition.includes(element.tagName)) {
                continue;
            }

            const e = document.createElement('button');
            e.appendChild(document.createTextNode(commandName));
            e.setAttribute('data-command-name', commandName);
            e.classList.add('text-arrangement-command');
            e.addEventListener(
                'click',
                (function(textField, operation){
                    return function(){
                        function getLineHead(text, start){
                            for (var i = start - 1; i >= 0; i--) {
                                if (text.charAt(i) == '\n') {
                                    if (i == text.length - 1) {
                                        return i;
                                    }
                                    return i + 1;
                                }
                            }

                            return 0;
                        }

                        function getLineTail(text, start){
                            for (var i = start; i < text.length; i++) {
                                if (text.charAt(i) == '\n') {
                                    if (i == 0) {
                                        return 0;
                                    }
                                    return i - 1;
                                }
                            }

                            return text.length - 1;
                        } 

                        const all = textField.value;
                        const charsSelectionStart = textField.selectionStart;
                        const charsSelectionEnd = textField.selectionEnd;
                        const selectedChars = all.substr(charsSelectionStart, charsSelectionEnd - charsSelectionStart);

                        const linesSelectionStart = getLineHead(all, charsSelectionStart);
                        const linesSelectionEnd = getLineTail(all, charsSelectionEnd);
                        const selectedLines = all.substr(linesSelectionStart, linesSelectionEnd - linesSelectionStart);

                        const [mode, replaced, [s, e]] = operation(selectedChars, selectedLines);

                        const selectionStart = mode == 'lines' ? linesSelectionStart : charsSelectionStart;
                        const selectionEnd = mode == 'lines' ? linesSelectionEnd : charsSelectionEnd;

                        const after = all.substr(0, selectionStart) + replaced + all.substr(selectionEnd);

                        textField.value = after;

                        function calcPosition(offset, selectionStart, replaced){
                            if (offset >= 0) {
                                return selectionStart + offset;
                            } else {
                                return selectionStart + (replaced.length + offset);
                            }
                        }

                        textField.setSelectionRange(
                            calcPosition(s, selectionStart, replaced),
                            calcPosition(e, selectionStart, replaced)
                        );

                        textField.focus();
                    };
                })(element, operation)
            );
            
            div.appendChild(e);
        }

        body.appendChild(div);
        return div;
    }

    const generateUniqueId = (function(){
        var serial = 1;

        return function(){
            return (serial++).toString();
        };
    })();

    const cache = {};

    var lastMenu = null;
    var lastHidingHandle = null;

    document.addEventListener(
        'focusin',
        function(x){
            function isTextField(node){
                return node != null &&
                       (
                           (node.tagName == 'INPUT' && node.getAttribute('type') == 'text') ||
                           node.tagName == 'TEXTAREA'
                       );
            }

            function isMenu(node){
                return node != null &&
                       (node.classList.contains(textMenuClass) || node.classList.contains(textCommandClass));
            }

            function isTextArrangeable(node){
                const ignoredElementNames = ['tags'];

                return isTextField(node) &&
                       !ignoredElementNames.includes(node.getAttribute('name'));
            }

            if (!isMenu(x.target) && lastMenu != null) {
                lastMenu.classList.add('hidden');
                lastMenu = null;
            }

            if (!isTextArrangeable(x.target)) {
                return;
            }

            function requireMenu(element){
                const idAttributeName = 'data-text-field-id';
                var id = element.getAttribute(idAttributeName);
    
                if (!element.hasAttribute(idAttributeName) || (id != null && !(id in cache))) {
                    id = generateUniqueId();
                    element.setAttribute(idAttributeName, id);

                    const menu = createMenu(element);
                    menu.setAttribute('data-id', id);

                    cache[id] = menu;
                    return menu;
                } else {
                    return cache[id];
                }
            }

            function getMenuOriginPosition(element){
                const boundingClientRect = element.getBoundingClientRect();

                return {
                    x: boundingClientRect.x + window.pageXOffset,
                    y: boundingClientRect.y + window.pageYOffset + element.clientHeight
                };
            }

            const menu = requireMenu(x.target);

            const position = getMenuOriginPosition(x.target);
            menu.style.left = position.x + 'px';
            menu.style.top = position.y + 'px';

            const right = menu.getBoundingClientRect().x + menu.clientWidth + window.pageXOffset;

            if (right > window.innerWidth - 20) {
                menu.style.left = (position.x - (right - (window.innerWidth - 20))) + 'px';
            }

            menu.classList.remove('hidden');

            lastMenu = menu;

            if (lastHidingHandle != null) {
                clearTimeout(lastHidingHandle);
                lastHidingHandle = null;
            }
        }
    );

    document.addEventListener(
        'focusout',
        function(x){
            const m = lastMenu;

            if (m == null || (x.relatedTarget != null && x.relatedTarget.classList.contains(textCommandClass))) {
                return;
            }

            lastHidingHandle = setTimeout(
                function(){
                    if (lastMenu != null && lastMenu === m) {
                        lastMenu.classList.add('hidden');
                        lastMenu = null;
                    }
                },
                10
            );
        }
    );
})(document, window);