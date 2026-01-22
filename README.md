# Kernel-Exploiter

Private exploit repository for dooz.

## Structure

```
/
├── web/
│   └── index.html      # Dashboard UI
├── exploits/
│   ├── gate.sh         # Detection script
│   ├── CVE-2021-4034/  # PwnKit
│   │   └── run.sh
│   ├── CVE-2022-0847/  # DirtyPipe
│   │   └── run.sh
│   └── CVE-2016-5195/  # DirtyCOW
│       └── run.sh
└── README.md
```

## Adding Exploits

1. Create folder: `exploits/CVE-YYYY-XXXX/`
2. Add `run.sh` (main exploit script)
3. Update `gate.sh` with detection logic

## gate.sh

Returns JSON with matching exploits:
```json
{"exploits":[{"cve":"CVE-2021-4034","name":"PwnKit","rate":99}]}
```

## API

- `/api/sysinfo` - System info
- `/api/scan` - Run gate.sh
- `/api/exploit` - Execute exploit
- `/api/exec` - Shell command
- `/api/files` - List directory
- `/api/destruct` - Cleanup
