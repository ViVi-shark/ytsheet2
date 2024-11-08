// 目次 ----------------------------------------
(() => {
    /** @var {Array.<{index: int, node: HTMLElement, title: string}>} */
    const contents = [];
    document.querySelectorAll('.in-toc').forEach(
        /** @param {HTMLElement} node */node => {
            const title = node.dataset.contentTitle ?? node.textContent;
            contents.push({index: contents.length, node, title});
        }
    );

    if (contents.length > 0) {
        const tocNode = document.createElement('div');
        tocNode.classList.add('toc-root', 'color-set');

        const ul = document.createElement('ul');
        ul.classList.add('content-list');
        tocNode.appendChild(ul);

        let lastHighlighterHandle;

        const onUpdate = x => {
            setTimeout(
                () => document.dispatchEvent(new Event('update-toc')),
                1
            );
        };

        /**
         * @return {HTMLElement}
         */
        function getContainerByContentNode(node) {
            return node.tagName.match(/^(h[1-6]|dt|summary)$/i) ? node.parentNode : node;
        }

        for (const content of contents) {
            const li = document.createElement('li');
            li.dataset.index = content.index.toString();
            li.textContent = content.title;
            li.addEventListener(
                'click',
                (node => {
                    return () => {
                        const targetY = node.getBoundingClientRect().top + window.scrollY - (document.getElementById('header-menu')?.clientHeight ?? 0) - 30;
                        const distanceY = Math.abs(targetY - window.scrollY);
                        window.scrollTo({
                            top: targetY,
                            left: 0,
                            behavior: 'smooth'
                        });

                        if (lastHighlighterHandle != null) {
                            clearTimeout(lastHighlighterHandle);
                            lastHighlighterHandle = null;
                        }

                        lastHighlighterHandle = setTimeout(
                            () => {
                                const container = getContainerByContentNode(node);

                                container.classList.remove('highlight-once');

                                setTimeout(
                                    () => {
                                        container.classList.add('highlight-once');
                                    },
                                    1
                                );
                            },
                            distanceY / 2
                        );
                    };
                })(content.node)
            );

            new MutationObserver(onUpdate).observe(
                getContainerByContentNode(content.node),
                {attributes: true}
            );

            ul.appendChild(li);
        }

        document.addEventListener(
            'update-toc',
            () => {
                let numberOfHiddenContents = 0;

                for (const content of contents) {
                    const visible = content.node.getBoundingClientRect().height > 0;
                    ul.querySelector(`li[data-index="${content.index}"]`).classList.toggle('hidden', !visible);

                    if (!visible) {
                        numberOfHiddenContents++;
                    }
                }

                tocNode.classList.toggle('hidden', numberOfHiddenContents === contents.length);
            }
        );
        document.dispatchEvent(new Event('update-toc'));

        {
            const sectionIds = [];

            for (const content of contents) {
                const section = content.node.closest('article > form > section[id]');

                if (section == null || sectionIds.includes(section.id)) {
                    continue;
                }

                sectionIds.push(section.id);
            }

            for (const id of sectionIds) {
                new MutationObserver(onUpdate).observe(document.getElementById(id), {attributes: true});
            }
        }

        new MutationObserver(onUpdate).observe(document.body, {attributes: true});

        document.querySelector('body').appendChild(tocNode);
    }
})();
