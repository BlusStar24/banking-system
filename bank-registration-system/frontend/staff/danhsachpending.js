const API_BASE = `http://${window.location.hostname}:5053/workflow/account`;

// Hàm tải danh sách pending
async function loadPending() {
  const tableBody = document.getElementById("pendingTable");
  tableBody.innerHTML = "<tr><td colspan='5'>Đang tải...</td></tr>";

  try {
    const res = await fetch(`${API_BASE}/pending`);
    const data = await res.json();

    if (data.length === 0) {
      tableBody.innerHTML = "<tr><td colspan='5'>Không có task pending</td></tr>";
      return;
    }

    // Render ra bảng
    tableBody.innerHTML = data
      .map(
        (task) => `
        <tr>
          <td>${task.caseId}</td>
          <td>${task.taskId}</td>
          <td>${task.customer ? task.customer.name || "N/A" : "N/A"}</td>
          <td>${task.state}</td>
          <td>
            <button class="btn btn-success btn-sm" onclick="reviewTask('${task.taskId}', '${task.caseId}', 'approved')">Approve</button>
            <button class="btn btn-danger btn-sm" onclick="reviewTask('${task.taskId}', '${task.caseId}', 'rejected')">Reject</button>
          </td>
        </tr>
      `
      )
      .join("");
  } catch (err) {
    tableBody.innerHTML = `<tr><td colspan='5' class="text-danger">Lỗi tải dữ liệu: ${err.message}</td></tr>`;
  }
}

// Hàm gọi API review
async function reviewTask(taskId, caseId, status) {
  if (!confirm(`Bạn có chắc muốn ${status} caseId=${caseId}?`)) return;

  try {
    const res = await fetch(`${API_BASE}/review`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify({ taskId, caseId, status }),
    });

    const data = await res.json();
    if (!res.ok) {
      alert("Lỗi: " + data.error);
    } else {
      alert(data.message);
      loadPending(); // reload danh sách
    }
  } catch (err) {
    alert("Lỗi: " + err.message);
  }
}

// Tải danh sách pending khi load trang
window.addEventListener("DOMContentLoaded", loadPending);
