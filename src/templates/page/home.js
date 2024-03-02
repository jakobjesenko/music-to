
document.querySelector('#run-jobs').addEventListener('click', () => {
    fetch('/run-jobs', {
        method: 'POST',
        headers: {
            'content-type': 'text/plain; charset=UTF-8'
        }
    }).then(
        res => res.text(), () => console.log('Something went wrong.')
    ).then(text => console.log(text), () => console.log('Something went wrong.'));
});