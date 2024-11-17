{
    /**
     * @param {HTMLElement} node
     */
    function nodeToText(node) {
        const parts = [];

        node.childNodes.forEach(
            child => {
                if (child.nodeName === '#text') {
                    parts.push(child.textContent);
                } else if (child instanceof HTMLElement) {
                    switch (child.nodeName) {
                        case '#text':
                            break;
                        case 'SPAN':
                            if (child.classList.contains('underline')) {
                                parts.push(`__${nodeToText(child)}__`);
                            } else if (child.classList.contains('oblique')) {
                                parts.push(`<i>${nodeToText(child)}</i>`);
                            } else {
                                console.warn(`Unexpected classes: ${[...child.classList].join(', ')}`);
                                parts.push(child.textContent);
                            }
                            break;
                        case 'I':
                            if (child.classList.contains('s-icon')) {
                                const textContent = child.textContent.trim();
                                parts.push(
                                    textContent.startsWith('[')
                                        ? textContent
                                        : `[${textContent}]`
                                );
                            } else {
                                parts.push(nodeToText(child));
                            }
                            break;
                        case 'A':
                            parts.push(nodeToText(child.querySelector('.text') ?? child));
                            break;
                        default:
                            console.warn(`Unexpected node type: ${child.nodeName}`);
                            parts.push(child.textContent);
                            break;
                    }
                } else {
                    console.warn(`Unexpected node type: ${child.nodeName}`);
                }
            }
        );

        return parts.join('');
    }

    /**
     * @param {HTMLElement} section
     */
    function sectionToText(section) {
        const lines = [
            nodeToText(section.querySelector('h5, h6')),
        ];

        section.querySelectorAll('p').forEach(
            p => lines.push(nodeToText(p))
        );

        return lines.join('\n');
    }

    document.querySelectorAll('main article .skills h5').forEach(
        headline => {
            const text = sectionToText(headline.closest('section'));

            const buttonToCopy = document.createElement('button');
            buttonToCopy.classList.add('to-copy');
            buttonToCopy.addEventListener(
                'click',
                () => navigator.clipboard.writeText(text)
            );

            headline.parentNode.appendChild(buttonToCopy);
        }
    );
}
