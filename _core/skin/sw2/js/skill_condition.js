if (document.querySelector('body.individualization.mount') != null) {
    /** @var {Array<string>} */
    const availableRidingNames = [];
    document.querySelectorAll('.skills .riding-checks .active').forEach(
        node => availableRidingNames.push(node.textContent.trim())
    );

    document.querySelectorAll('main article .skills h5').forEach(
        h5 => {
            const m = h5.innerHTML.match(/【\s*(前提|拡張)\s*[:：]\s*([^<>]+?)\s*】/);
            if (m == null) {
                return;
            }

            const mode = m[1];
            const referredRidingName = m[2];

            const state =
                availableRidingNames.includes(`【${referredRidingName}】`)
                    ? 'available'
                    : mode === '前提' ? 'non-available' : 'limited-available';

            h5.innerHTML = h5.innerHTML.replace(
                m[0],
                `<span class="condition">【<i class="icon ${state}"></i>${mode}：${referredRidingName}】</span>`
            );

            h5.closest('section').classList.toggle('non-available', state === 'non-available');
        }
    );
}
