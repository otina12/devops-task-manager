const taskList = document.getElementById('taskList');
const emptyMsg = document.getElementById('emptyMsg');
const taskForm = document.getElementById('taskForm');
const titleInput = document.getElementById('titleInput');

async function loadTasks() {
  const res = await fetch('/tasks');
  const tasks = await res.json();

  taskList.innerHTML = '';
  emptyMsg.style.display = tasks.length === 0 ? 'block' : 'none';

  tasks.forEach(task => {
    const li = document.createElement('li');
    li.className = 'task' + (task.completed ? ' done' : '');

    const title = document.createElement('span');
    title.className = 'task-title';
    title.textContent = task.title;

    const toggleBtn = document.createElement('button');
    toggleBtn.className = 'btn-toggle';
    toggleBtn.textContent = task.completed ? 'Undo' : 'Complete';
    toggleBtn.addEventListener('click', () => toggleTask(task.id));

    const deleteBtn = document.createElement('button');
    deleteBtn.className = 'btn-delete';
    deleteBtn.textContent = 'Delete';
    deleteBtn.addEventListener('click', () => deleteTask(task.id));

    li.appendChild(title);
    li.appendChild(toggleBtn);
    li.appendChild(deleteBtn);
    taskList.appendChild(li);
  });
}

taskForm.addEventListener('submit', async (e) => {
  e.preventDefault();
  const title = titleInput.value.trim();
  if (!title) return;

  await fetch('/tasks', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ title })
  });

  titleInput.value = '';
  loadTasks();
});

async function toggleTask(id) {
  await fetch(`/tasks/${id}`, { method: 'PATCH' });
  loadTasks();
}

async function deleteTask(id) {
  await fetch(`/tasks/${id}`, { method: 'DELETE' });
  loadTasks();
}

loadTasks();
