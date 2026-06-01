async function uploadFile()
{
    const fileInput = document.getElementById('fileInput');
    const status = document.getElementById('status');
    const progressBar = document.getElementById('progressBar');
    const progressContainer = document.getElementById('progressContainer');
    const uploadBtn = document.getElementById('uploadBtn');

    if(fileInput.files.length === 0)
    {
        status.textContent = 'Select a file to upload.';
        return;
    }

    const file = fileInput.files[0];
    const chunkSize = 1024 * 1024 * 10; //10MB
    let offset = 0;

    progressContainer.style.display = 'block';
    uploadBtn.disabled = true;
    uploadBtn.style.opacity = '0.5';
    status.textContent = 'Preparing to upload...';

    while(offset < file.size)
    {
        const chunk = file.slice(offset, offset + chunkSize);
        await fetch('/upload_chunk', {
            method: 'POST',
            headers: {
                'File-Name': file.name,
            },
            body: chunk
        });
        offset += chunkSize;

        let progress = Math.min(100, Math.round((offset / file.size) * 100));
        progressBar.style.width = `${progress}%`;
        status.textContent = `${Math.round(progress)}% (${(offset / (1024 * 1024)).toFixed(1)} MB / ${(file.size / (1024 * 1024)).toFixed(1)} MB)`;
    }

    status.textContent = 'File uploaded';
    progressBar.style.backgroundColor = '#34C759';
    setTimeout(() => {
        window.location.reload();
    }, 1000);
}