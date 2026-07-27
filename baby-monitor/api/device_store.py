"""闲置手机监控节点状态存储（内存，可后续换 Redis）"""

from __future__ import annotations

import time
from dataclasses import dataclass, field


@dataclass
class CameraNodeState:
    device_id: str
    device_name: str
    behavior: str = "unknown"
    behavior_cn: str = "未知"
    confidence: float = 0.0
    alert: bool = False
    alert_message: str = ""
    movement: float = 0.0
    torso_angle: float = 0.0
    annotated_image_b64: str | None = None
    last_seen: float = field(default_factory=time.time)
    online: bool = True


class DeviceStore:
  """管理家中各监控节点（闲置手机）的最新状态"""

  OFFLINE_SECONDS = 30  # 超过此秒数无心跳视为离线

  def __init__(self) -> None:
    self._nodes: dict[str, CameraNodeState] = {}

  def upsert(self, state: CameraNodeState) -> None:
    state.last_seen = time.time()
    state.online = True
    self._nodes[state.device_id] = state

  def get(self, device_id: str) -> CameraNodeState | None:
    node = self._nodes.get(device_id)
    if node:
      self._refresh_online(node)
    return node

  def list_all(self) -> list[CameraNodeState]:
    now = time.time()
    for node in self._nodes.values():
      node.online = (now - node.last_seen) < self.OFFLINE_SECONDS
    return sorted(self._nodes.values(), key=lambda n: n.device_name)

  def _refresh_online(self, node: CameraNodeState) -> None:
    node.online = (time.time() - node.last_seen) < self.OFFLINE_SECONDS


store = DeviceStore()
