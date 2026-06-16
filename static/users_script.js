fetch("/peers").then(
    response => response.json()
).then(
    data => {
        const peersList = document.getElementById("peers-list");
        data.peers.forEach(peer => {
            const listItem = document.createElement("li");
            listItem.textContent = peer;
            peersList.appendChild(listItem);
        });
    }
);