let tasks = [];
let nextId = 1;

const getAll = () => tasks;

const getById = (id) => tasks.find(t => t.id === id);

const create = (title) => {
  const task = { id: nextId++, title, completed: false };
  tasks.push(task);
  return task;
};

const toggle = (id) => {
  const t = getById(id);
  if (t) t.completed = !t.completed;
  return t;
};

const remove = (id) => {
  const idx = tasks.findIndex(t => t.id === id);
  if (idx === -1) return false;
  tasks.splice(idx, 1);
  return true;
};

const reset = () => { tasks = []; nextId = 1; };

module.exports = { getAll, getById, create, toggle, remove, reset };
