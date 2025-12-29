#!/usr/bin/env python3
"""
Fetch Blocks from Manifest

Reads a manifest file (manifest_v14.json, manifest_v15.json, etc.) and fetches
the actual block data, events, and metadata from RPC.

Usage:
    python3 scripts/fetch_from_manifest.py <chain> <version>

Arguments:
    chain   - Required: kusama or polkadot
    version - Required: 14, 15, or 16

Examples:
    python3 scripts/fetch_from_manifest.py kusama 14
    python3 scripts/fetch_from_manifest.py polkadot 15
"""

import json
import ssl
import sys
import time
import http.client
import threading
from concurrent.futures import ThreadPoolExecutor, as_completed
from pathlib import Path
from threading import Lock
from typing import Dict, List, Optional, Tuple
from urllib.parse import urlparse


# Base directory
CHAIN_DIR = Path(__file__).parent.parent / "chain"

# Parallel workers
MAX_WORKERS = 2

# Batch size for RPC calls
BATCH_SIZE = 4

# Retry configuration
MAX_RETRIES = 3
RETRY_DELAY = 1.0


class RPCClient:
    """RPC client with thread-local connections, batching, and caching."""

    def __init__(self, endpoints: List[str]):
        self.endpoints = endpoints
        self.current_idx = 0
        self.lock = Lock()
        self.thread_local = threading.local()
        self.block_hash_cache: Dict[int, str] = {}
        self.cache_lock = Lock()
        self._find_working_endpoint()

    def _get_connection(self, endpoint: str) -> http.client.HTTPSConnection:
        """Get or create a thread-local connection for the endpoint."""
        parsed = urlparse(endpoint)
        host = parsed.netloc

        if not hasattr(self.thread_local, 'connections'):
            self.thread_local.connections = {}

        if host not in self.thread_local.connections:
            ctx = ssl.create_default_context()
            ctx.check_hostname = False
            ctx.verify_mode = ssl.CERT_NONE
            self.thread_local.connections[host] = http.client.HTTPSConnection(host, context=ctx, timeout=30)

        return self.thread_local.connections[host]

    def _raw_call(self, endpoint: str, payload: bytes) -> Optional[Dict]:
        """Make raw HTTP call with thread-local connection."""
        parsed = urlparse(endpoint)
        conn = self._get_connection(endpoint)

        try:
            conn.request("POST", parsed.path or "/", payload, {
                "Content-Type": "application/json"
            })
            response = conn.getresponse()
            data = response.read().decode('utf-8')

            # Check for rate limiting
            if response.status == 429:
                print(f"    ⚠️  Rate limited (HTTP 429) by {parsed.netloc}")
                return None
            if response.status == 503:
                print(f"    ⚠️  Service unavailable (HTTP 503) from {parsed.netloc}")
                return None
            if response.status != 200:
                print(f"    ⚠️  HTTP {response.status} from {parsed.netloc}")
                return None

            result = json.loads(data)

            # Check for rate limit errors in JSON response
            if isinstance(result, dict) and "error" in result:
                error_msg = str(result["error"]).lower()
                if "rate" in error_msg or "limit" in error_msg or "too many" in error_msg:
                    print(f"    ⚠️  Rate limited: {result['error']}")
                    return None

            return result
        except Exception as e:
            print(f"    ⚠️  Connection error: {type(e).__name__}: {e}")
            host = parsed.netloc
            ctx = ssl.create_default_context()
            ctx.check_hostname = False
            ctx.verify_mode = ssl.CERT_NONE
            self.thread_local.connections[host] = http.client.HTTPSConnection(host, context=ctx, timeout=30)
            return None

    def _find_working_endpoint(self):
        """Find a working RPC endpoint."""
        for i, endpoint in enumerate(self.endpoints):
            payload = json.dumps({
                "jsonrpc": "2.0",
                "method": "system_chain",
                "params": [],
                "id": 1,
            }).encode('utf-8')
            result = self._raw_call(endpoint, payload)
            if result and "result" in result:
                self.current_idx = i
                print(f"  Using endpoint: {endpoint}")
                return
        raise Exception("No working endpoint found")

    @property
    def endpoint(self) -> str:
        return self.endpoints[self.current_idx]

    def call(self, method: str, params: List = None) -> Optional[Dict]:
        """Make a single RPC call."""
        payload = json.dumps({
            "jsonrpc": "2.0",
            "method": method,
            "params": params or [],
            "id": 1,
        }).encode('utf-8')

        result = self._raw_call(self.endpoint, payload)
        if result and "result" in result:
            return result["result"]
        return None

    def batch_call(self, calls: List[Tuple[str, List]]) -> List[Optional[Dict]]:
        """Make batch RPC calls."""
        if not calls:
            return []

        batch_payload = json.dumps([
            {
                "jsonrpc": "2.0",
                "method": method,
                "params": params,
                "id": i,
            }
            for i, (method, params) in enumerate(calls)
        ]).encode('utf-8')

        result = self._raw_call(self.endpoint, batch_payload)

        if not result:
            return [None] * len(calls)

        if isinstance(result, dict):
            return [None] * len(calls)

        results = [None] * len(calls)
        for item in result:
            if isinstance(item, dict) and "id" in item:
                idx = item["id"]
                if 0 <= idx < len(calls):
                    results[idx] = item.get("result")
        return results

    def get_block_hash(self, block_number: int) -> Optional[str]:
        """Get block hash with caching."""
        with self.cache_lock:
            if block_number in self.block_hash_cache:
                return self.block_hash_cache[block_number]

        result = self.call("chain_getBlockHash", [block_number])
        if result:
            with self.cache_lock:
                self.block_hash_cache[block_number] = result
        return result

    def get_block_hashes_batch(self, block_numbers: List[int]) -> Dict[int, str]:
        """Get multiple block hashes in batch."""
        with self.cache_lock:
            uncached = [bn for bn in block_numbers if bn not in self.block_hash_cache]

        if uncached:
            calls = [("chain_getBlockHash", [bn]) for bn in uncached]
            results = self.batch_call(calls)
            with self.cache_lock:
                for bn, result in zip(uncached, results):
                    if result:
                        self.block_hash_cache[bn] = result

        with self.cache_lock:
            return {bn: self.block_hash_cache.get(bn) for bn in block_numbers}

    def get_block(self, block_hash: str) -> Optional[Dict]:
        return self.call("chain_getBlock", [block_hash])

    def get_runtime_version(self, block_hash: str) -> Optional[Dict]:
        return self.call("state_getRuntimeVersion", [block_hash])

    def get_metadata(self, block_hash: str) -> Optional[str]:
        return self.call("state_getMetadata", [block_hash])

    def get_metadata_at_version(self, block_hash: str, version: int) -> Optional[str]:
        """Get metadata at a specific version using state_call."""
        version_param = f"0x{version:02x}000000"
        result = self.call("state_call", [
            "Metadata_metadata_at_version",
            version_param,
            block_hash
        ])

        if not result or result == "0x00" or len(result) < 4:
            return None

        if result.startswith("0x01"):
            return self._decode_opaque_metadata(result[4:])
        return None

    def _decode_opaque_metadata(self, hex_data: str) -> Optional[str]:
        """Decode OpaqueMetadata from SCALE encoding."""
        try:
            if not hex_data:
                return None
            first_byte = int(hex_data[0:2], 16)
            if (first_byte & 0b11) == 0b00:
                data_start = 2
            elif (first_byte & 0b11) == 0b01:
                data_start = 4
            elif (first_byte & 0b11) == 0b10:
                data_start = 8
            else:
                num_bytes = (first_byte >> 2) + 4
                data_start = 2 + (num_bytes * 2)
            return "0x" + hex_data[data_start:]
        except Exception:
            return None

    def get_events(self, block_hash: str) -> Optional[str]:
        events_key = "0x26aa394eea5630e07c48ae0c9558cef780d41e5e16056765bc8461851072c9d7"
        return self.call("state_getStorage", [events_key, block_hash])

    def fetch_block_and_events_batch(self, block_numbers: List[int]) -> Tuple[List[Dict], List[Dict]]:
        """Fetch blocks and events for multiple block numbers using batch calls with retry."""
        for attempt in range(MAX_RETRIES):
            try:
                blocks, events = self._fetch_block_and_events_batch_impl(block_numbers)

                # Check if we got all expected blocks
                if len(blocks) == len(block_numbers):
                    return blocks, events

                # If missing blocks on last attempt, return what we have
                if attempt == MAX_RETRIES - 1:
                    return blocks, events

                # Retry if missing blocks
                time.sleep(RETRY_DELAY * (attempt + 1))

            except Exception as e:
                if attempt == MAX_RETRIES - 1:
                    print(f"    Warning: Batch failed after {MAX_RETRIES} retries: {e}")
                    return [], []
                time.sleep(RETRY_DELAY * (attempt + 1))

        return [], []

    def _fetch_block_and_events_batch_impl(self, block_numbers: List[int]) -> Tuple[List[Dict], List[Dict]]:
        """Implementation of batch fetch without retry."""
        # First, get all block hashes
        hash_map = self.get_block_hashes_batch(block_numbers)

        # Build batch calls for blocks and events
        valid_blocks = [(bn, h) for bn, h in hash_map.items() if h]

        if not valid_blocks:
            return [], []

        # Batch call for blocks
        block_calls = [("chain_getBlock", [h]) for _, h in valid_blocks]
        block_results = self.batch_call(block_calls)

        # Batch call for events
        events_key = "0x26aa394eea5630e07c48ae0c9558cef780d41e5e16056765bc8461851072c9d7"
        event_calls = [("state_getStorage", [events_key, h]) for _, h in valid_blocks]
        event_results = self.batch_call(event_calls)

        blocks = []
        events = []

        for (bn, _), block_data, event_data in zip(valid_blocks, block_results, event_results):
            if block_data:
                header = block_data["block"]["header"]
                blocks.append({
                    "blockNumber": bn,
                    "extrinsics": block_data["block"]["extrinsics"],
                    "header": {
                        "digest": header.get("digest", {}),
                        "extrinsicsRoot": header.get("extrinsicsRoot"),
                        "number": header.get("number"),
                        "parentHash": header.get("parentHash"),
                        "stateRoot": header.get("stateRoot"),
                    }
                })

            if event_data:
                events.append({"blockNumber": bn, "events": event_data})

        return blocks, events


def expand_test_blocks(test_blocks: List) -> List[int]:
    """
    Expand manifest test_blocks format to list of block numbers.
    [block_number, count] -> range of consecutive blocks
    block_number -> single block
    """
    result = []
    for item in test_blocks:
        if isinstance(item, list):
            start, count = item
            result.extend(range(start, start + count))
        else:
            result.append(item)
    return sorted(set(result))


def fetch_blocks_parallel(client: RPCClient, block_numbers: List[int]) -> Tuple[List[Dict], List[Dict]]:
    """Fetch blocks and events in parallel batches."""
    all_blocks = []
    all_events = []

    # Split into batches
    batches = [block_numbers[i:i + BATCH_SIZE] for i in range(0, len(block_numbers), BATCH_SIZE)]

    print(f"  Processing {len(batches)} batches of up to {BATCH_SIZE} blocks each...")

    with ThreadPoolExecutor(max_workers=MAX_WORKERS) as executor:
        futures = {
            executor.submit(client.fetch_block_and_events_batch, batch): i
            for i, batch in enumerate(batches)
        }

        completed = 0
        for future in as_completed(futures):
            completed += 1
            blocks, events = future.result()
            all_blocks.extend(blocks)
            all_events.extend(events)

            if completed % 5 == 0 or completed == len(batches):
                print(f"    Completed {completed}/{len(batches)} batches ({len(all_blocks)} blocks)")

    return all_blocks, all_events


def main():
    # Check arguments
    if len(sys.argv) != 3:
        print("Usage: python3 scripts/fetch_from_manifest.py <chain> <version>")
        print()
        print("Arguments:")
        print("  chain   - Required: kusama or polkadot")
        print("  version - Required: 14, 15, or 16")
        print()
        print("Examples:")
        print("  python3 scripts/fetch_from_manifest.py kusama 14")
        print("  python3 scripts/fetch_from_manifest.py polkadot 15")
        sys.exit(1)

    chain = sys.argv[1].lower()

    # Validate chain
    if chain not in ["kusama", "polkadot"]:
        print(f"Error: Invalid chain '{chain}'")
        print("Chain must be 'kusama' or 'polkadot'")
        sys.exit(1)

    # Validate version
    try:
        version = int(sys.argv[2])
        if version not in [14, 15, 16]:
            raise ValueError()
    except ValueError:
        print(f"Error: Invalid version '{sys.argv[2]}'")
        print("Version must be 14, 15, or 16")
        sys.exit(1)

    # Check manifest exists
    manifest_file = CHAIN_DIR / chain / f"manifest_v{version}.json"
    if not manifest_file.exists():
        print(f"Error: Manifest not found: {manifest_file}")
        print(f"Run create_manifest.py first or check the path.")
        sys.exit(1)

    print(f"Fetching data for {chain} v{version}")
    print(f"Reading manifest: {manifest_file}")

    # Load manifest
    with open(manifest_file) as f:
        manifest = json.load(f)

    endpoints = manifest["rpc_endpoints"]
    runtime_upgrades = manifest["runtime_upgrades"]
    test_blocks = manifest["test_blocks"]

    # Expand test blocks
    block_numbers = expand_test_blocks(test_blocks)
    print(f"  Runtime upgrades: {len(runtime_upgrades)}")
    print(f"  Blocks to fetch: {len(block_numbers)}")

    # Create RPC client
    client = RPCClient(endpoints)

    # Create output directory
    output_dir = CHAIN_DIR / chain / f"v{version}"
    output_dir.mkdir(parents=True, exist_ok=True)

    # Fetch blocks and events in parallel
    print(f"\nFetching {len(block_numbers)} blocks (parallel + batched)...")
    blocks, events = fetch_blocks_parallel(client, block_numbers)

    # Write blocks.jsonl
    blocks_file = output_dir / "blocks.jsonl"
    with open(blocks_file, "w") as f:
        for block in sorted(blocks, key=lambda x: x["blockNumber"]):
            f.write(json.dumps(block) + "\n")
    print(f"\nWritten {len(blocks)} blocks to {blocks_file.name}")

    # Write events.jsonl
    events_file = output_dir / "events.jsonl"
    with open(events_file, "w") as f:
        for event in sorted(events, key=lambda x: x["blockNumber"]):
            f.write(json.dumps(event) + "\n")
    print(f"Written {len(events)} events to {events_file.name}")

    # Fetch metadata for each runtime upgrade
    print(f"\nFetching metadata for {len(runtime_upgrades)} runtime versions...")
    runtime_upgrades_full = []

    for upgrade in runtime_upgrades:
        spec_version = upgrade["spec_version"]
        block_number = upgrade["block_number"]

        metadata_file = output_dir / f"metadata_spec{spec_version}.json"

        block_hash = client.get_block_hash(block_number)
        if not block_hash:
            print(f"  Warning: Could not get hash for block {block_number}")
            continue

        # Get metadata
        if version == 14:
            metadata = client.get_metadata(block_hash)
        else:
            metadata = client.get_metadata_at_version(block_hash, version)

        runtime = client.get_runtime_version(block_hash)

        if metadata and runtime:
            # Write individual metadata file
            metadata_data = {
                "specName": runtime.get("specName", ""),
                "specVersion": spec_version,
                "blockNumber": block_number,
                "blockHash": block_hash,
                "metadata": metadata,
            }
            with open(metadata_file, "w") as f:
                json.dump(metadata_data, f)
            print(f"  Written metadata for spec {spec_version}")

            # Add to runtime upgrades list
            runtime_upgrades_full.append({
                "spec_version": spec_version,
                "block_number": block_number,
                "block_hash": block_hash,
                "metadata_version": version,
            })

    # Write runtime_upgrades_v{version}.json
    upgrades_file = output_dir / f"runtime_upgrades_v{version}.json"
    with open(upgrades_file, "w") as f:
        json.dump(runtime_upgrades_full, f, indent=2)
    print(f"\nWritten {len(runtime_upgrades_full)} runtime upgrades to {upgrades_file.name}")

    print(f"\nDone! Output in: {output_dir}")


if __name__ == "__main__":
    main()
