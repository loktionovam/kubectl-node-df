# kubectl-node-df

`kubectl` plugin that prints node filesystem usage from the kubelet Summary API.

It shows `node.fs` and, when available, `node.runtime.imageFs` and
`node.runtime.containerFs`,
and prints eviction thresholds from the kubelet `configz` endpoint.

## Requirements

- `kubectl` in `PATH` with a configured `KUBECONFIG`
- `jq`
- Access to kubelet Summary API via `kubectl get --raw` (RBAC / API server)
- Access to kubelet `configz` via `kubectl get --raw` for eviction headroom
  (optional; unavailable values are displayed as `-`)

## Installation

### Krew

```bash
kubectl krew install node-df
```

### From source

Install the plugin to `$HOME/.local/bin`:

```bash
make install
```

Override install prefix:

```bash
sudo make install PREFIX=/usr/local
```

Uninstall:

```bash
make uninstall
```

## Usage

```bash
kubectl node-df [--inodes] [-o wide] [NODE...]
```

Options:

- `-i`, `--inodes` — show inode usage instead of bytes
- `-o`, `--output` — output format (only `wide` supported)
- `-h`, `--help` — help

Env:

- `NODE_DF_PARALLEL` — number of parallel requests (default `6`)

Examples:

```bash
kubectl node-df
kubectl node-df -o wide
kubectl node-df node-1 node-2
kubectl node-df --inodes
```

## Output

Default output shows node filesystem usage in GiB:

```
NODE                                 USED    AVAIL    TOTAL   USE%
node-a                              10.2G    36.8G    47.0G    22%
node-b                              96.5G    50.5G   147.0G    66%
```

`--inodes` shows inode usage and inode eviction headroom:

```
NODE                               INODE_USED   INODE_FREE  INODE_TOTAL   USE%  INODE_EVICT
node-a                                 146875     24519237     24666112     1%    +23285927
node-b                                1864229     75232731     77096960     2%    +71377883
```

`-o wide` adds eviction headroom columns. Headroom is `available - threshold`;
positive values mean the node is still above the hard eviction threshold.

```
NODE                                 USED    AVAIL    TOTAL   USE%  IMG_EVICT_HEADROOM  NODE_EVICT_HEADROOM  IMG_EVICT_HEADROOM%  NODE_EVICT_HEADROOM%
node-a                              10.2G    36.8G    47.0G    22%              +29.8G               +32.1G                 +63%                  +68%
node-b                              96.5G    50.5G   147.0G    66%              +28.5G               +35.8G                 +19%                  +24%
```

## Notes

- The plugin uses `kubectl get --raw /api/v1/nodes/<node>/proxy/stats/summary`.
- Eviction thresholds are read from `kubectl get --raw /api/v1/nodes/<node>/proxy/configz` (hard thresholds).
- If a node does not respond, the row shows `-`.
- `imagefs` and `containerfs` output depends on the container runtime configuration.

## Development

Run syntax checks, ShellCheck, and functional tests with a mocked Kubernetes API:

```bash
make check
```

## License

GNU General Public License v3.0. See [LICENSE](LICENSE).
