async function uploadFile()
{
    const fileInput = document.getElementById('fileInput');
    const status = document.getElementById('status');

    if(fileInput.files.length === 0)
    {
        status.textContent = 'Select a file to upload.';
        return;
    }

    const file = fileInput.files[0];
    const chunkSize = 1024 * 1024 * 10; //10MB
    let offset = 0;

    status.textContent = 'Uploading...';

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
        status.textContent = `Uploading... ${progress}% \n ${(offset / (1024 * 1024))} MB of ${(file.size / (1024 * 1024)).toFixed(2)} MB`;
    }

    status.textContent = 'File uploaded';
    window.location.reload();
}