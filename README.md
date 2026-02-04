# kubectl-node-df

`kubectl` plugin that prints node filesystem usage from the kubelet Summary API.

## Requirements

- `kubectl` in `PATH` with a configured `KUBECONFIG`
- `jq`
- Access to kubelet Summary API via `kubectl get --raw` (RBAC / API server)

## Installation

Make the file executable and place it in your `PATH`:

```bash
chmod +x kubectl-node-df
sudo mv kubectl-node-df /usr/local/bin/
```

Or via `make` (defaults to `$HOME/.local/bin` without sudo):

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
kubectl node df [--inodes] [NODE...]
```

Options:

- `-i`, `--inodes` — show inode usage instead of bytes
- `-h`, `--help` — help

Env:

- `NODE_DF_PARALLEL` — number of parallel requests (default `6`)

Examples:

```bash
kubectl node df
kubectl node df node-1 node-2
kubectl node df --inodes
```

## Output

By default, sizes are shown in GiB with usage percent:

```
NODE                             USED    AVAIL    TOTAL   USE%
node-1                           72.3G   101.7G   174.0G   42%
node-2                            18.9G    63.2G    82.1G   23%
node-3                           5.4G    20.6G    26.0G   21%
```

With `--inodes`:

```
NODE                          INODE_USED  INODE_FREE INODE_TOTAL   USE%
node-1                               1234      98765      99999     1%
node-2                              456      65432      70000     1%
```

## Notes

- The plugin uses `kubectl get --raw /api/v1/nodes/<node>/proxy/stats/summary`.
- If a node does not respond, the row shows `-`.
