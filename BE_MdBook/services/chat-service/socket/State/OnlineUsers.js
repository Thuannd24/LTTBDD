const map = new Map();

function setOnline(userId, socketId) {
  const key = String(userId);
  const sockets = map.get(key) || new Set();
  sockets.add(String(socketId));
  map.set(key, sockets);
}

function setOffline(userId, socketId) {
  const key = String(userId);
  const sockets = map.get(key);
  if (!sockets) {
    return;
  }

  sockets.delete(String(socketId));
  if (sockets.size === 0) {
    map.delete(key);
  }
}

function getSocketIds(userId) {
  return Array.from(map.get(String(userId)) || []);
}

function isOnline(userId) {
  return getSocketIds(userId).length > 0;
}

function listUserIds() {
  return Array.from(map.keys());
}

function clear() {
  map.clear();
}

module.exports = {
  setOnline,
  setOffline,
  getSocketIds,
  isOnline,
  listUserIds,
  clear,
};
