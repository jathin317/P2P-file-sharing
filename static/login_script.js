console.log('script loaded');
console.log('socket:', typeof io);

const socket = io();

document.querySelector('button').addEventListener('click', join);

let username = "";

function join()
{
    username = document.getElementById("username").value;
    if (!username)
    {
        alert("Please enter username");
        return;
    }
    socket.emit("join", { username: username });
    document.getElementById("login").style.display = "none";
    document.getElementById("usersList").style.display = "block";
}

socket.on("user_list", (data) => {
    const list = document.getElementById("peers");
    list.innerHTML = "";
    data.users.forEach(user => {
        if (user.username === username) return;
        const li = document.createElement("li");
        li.textContent = user.username;
        li.addEventListener("click", () => selectUser(user.sid, user.username))
        list.appendChild(li);
    });
});

function selectUser(sid, username)
{
    console.log(`Selected user: ${username}: ${sid}`);
    
    const fileDialog = document.getElementById("fileUpload");
    document.getElementById("receiver_username").innerText = `Sending file to ${username}`;
    fileDialog.showModal();

    const fileInput = document.getElementById("fileInput");
    const selectButton = document.getElementById("selectFileBtn");

    selectButton.onclick = () => fileInput.click();

    fileInput.addEventListener("change", () => {
        if (fileInput.files.length > 0)
        {
            const file = fileInput.files[0];
            document.getElementById("fileNameDisplay").innerText = file.name;
            document.getElementById("sendFileBtn").disabled = false;
        }
    })
}