console.log('script loaded');

const socket = io();

let peerConnection;
let dataChannel;
let receiverSid = "";

const rtcConfig = { iceServers: [] };

document.querySelector('#login-btn').addEventListener('click', join);

let username = "";

function join() {
    username = document.getElementById("username").value;
    if (!username) {
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
        li.addEventListener("click", () => selectUser(user.sid, user.username));
        list.appendChild(li);
    });
});

function selectUser(sid, targetUsername) {
    console.log(`Selected user: ${targetUsername}: ${sid}`);
    receiverSid = sid;

    const fileDialog = document.getElementById("fileUpload");
    document.getElementById("receiver_username").innerText = `Sending file to ${targetUsername}`;
    fileDialog.showModal();
    
    document.getElementById("closeFileUploadBtn").onclick = () => fileDialog.close();

    const fileInput = document.getElementById("fileInput");
    const selectButton = document.getElementById("selectFileBtn");
    const sendButton = document.getElementById("sendFileBtn");

    selectButton.onclick = () => fileInput.click();

    fileInput.addEventListener("change", () => {
        if (fileInput.files.length > 0) {
            const file = fileInput.files[0];
            document.getElementById("fileNameDisplay").innerText = file.name;
            sendButton.disabled = false;
            
            sendButton.onclick = () => {
                await initiateConnection();
                sendFile(file);
                fileDialog.close();
            };
        }
    });
}

//WebRTC Logic

async function initiateConnection() {
    peerConnection = new RTCPeerConnection(rtcConfig);

    dataChannel = peerConnection.createDataChannel("fileTransferChannel");
    setupDataChannel(dataChannel);

    peerConnection.onicecandidate = (event) => {
        if(event.candidate) {
            socket.emit("webrtc_signal", {
                target_sid: receiverSid,
                type: "candidate",
                candidate: event.candidate
            });
        }
    };

    const offer = await peerConnection.createOffer();
    await peerConnection.setLocalDescription(offer);

    socket.emit("webrtc_signal", {
        target_sid: receiverSid,
        type: "offer",
        sdp: peerConnection.localDescription
    });
}

socket.on("webrtc_signal", async (data) => {
    if (!peerConnection) {
        peerConnection = new RTCPeerConnection(rtcConfig);

        peerConnection.ondatachannel = (event) => {
            const receiveChannel = event.channel;
            setupDataChannel(receiveChannel);
        };

        peerConnection.onicecandidate = (event) => {
            if (event.candidate) {
                socket.emit("webrtc_signal", {
                    target_sid: data.sender_sid,
                    type: "candidate",
                    candidate: event.candidate
                });
            }
        };
    }
    
    if(data.type === "offer") {
        await peerConnection.setRemoteDescription(new RTCSessionDescription(data.sdp));
        const answer = await peerConnection.createAnswer();
        await peerConnection.setLocalDescription(answer);

        socket.emit("webrtc_signal", {
            target_sid: data.sender_sid,
            type: "answer",
            sdp: peerConnection.localDescription
        });
    }
    
    if(data.type === "answer") {
        await peerConnection.setRemoteDescription(new RTCSessionDescription(data.sdp));
    }

    if(data.type === "candidate") {
        await peerConnection.addIceCandidate(new RTCIceCandidate(data.candidate));
    }
});

// File Transfer Logic

function setupDataChannel(channel) {
    let receivedBuffers = [];
    let expectedSize = 0;
    let fileName = "downloaded_file";

    channel.onopen = () => console.log("Data channel open");
    channel.onclose = () => console.log("Data channel closed");

    channel.onmessage = (event) => {
        if (typeof event.data === 'string') {
            const meta = JSON.parse(event.data);
            expectedSize = meta.size;
            fileName = meta.name;
            console.log(`Receiving file: ${meta.name} (${expectedSize} bytes)`);
            receivedBuffers = [];
        } else {
            receivedBuffers.push(event.data);
            const currentSize = receivedBuffers.reduce((acc, buf) => acc + buf.byteLength, 0);
            
            if (currentSize === expectedSize) {
                const blob = new Blob(receivedBuffers);
                const link = document.createElement('a');
                link.href = URL.createObjectURL(blob);
                link.download = fileName;
                link.click();
            }
        }
    };
}

function sendFile(file) {
    const chunkSize = 16384; // 16KB chunks
    const reader = new FileReader();
    let offset = 0;

    dataChannel.onopen = () => {
        dataChannel.send(JSON.stringify({
            name: file.name,
            size: file.size
        }));
        readSlice(offset);
    };

    function readSlice(o) {
        const slice = file.slice(offset, o + chunkSize);
        reader.readAsArrayBuffer(slice);
    }

    reader.onload = (e) => {
        dataChannel.send(e.target.result);
        offset += e.target.result.byteLength;

        if (offset < file.size) {
            readSlice(offset);
        } else {
            console.log("File sent successfully!");
        }
    };
}