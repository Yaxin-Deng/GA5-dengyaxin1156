#!/usr/bin/env bash
set -euo pipefail

# Run self-BLAST of a protein FASTA and save tabular output with a header
# - Builds a protein BLAST DB from the provided FASTA
# - Runs blastp (self-alignment)
# - Prepends a header to the tabular output
# - Writes both .tab and .txt copies into the specified output directory

FASTA="/fs/ess/PAS2880/users/dengyaxin1156/TS_BAHD_project/00_raw/BAHD_ref_protein.fa"
OUTDIR="/fs/ess/PAS2880/users/dengyaxin1156/TS_BAHD_project/02_blast_self"
DB="$OUTDIR/BAHD_ref_prot_db"

# Tunable via environment variables
THREADS="${THREADS:-4}"
EVALUE="${EVALUE:-1e-5}"
MAX_TARGET_SEQS="${MAX_TARGET_SEQS:-1000}"

mkdir -p "$OUTDIR"

if [ ! -f "$FASTA" ]; then
  echo "ERROR: FASTA file not found: $FASTA" >&2
  exit 2
fi

if ! command -v makeblastdb >/dev/null 2>&1; then
  echo "ERROR: makeblastdb not found in PATH. Please load BLAST+ (makeblastdb)." >&2
  exit 3
fi

if ! command -v blastp >/dev/null 2>&1; then
  echo "ERROR: blastp not found in PATH. Please load BLAST+ (blastp)." >&2
  exit 4
fi

echo "[INFO] Building BLAST DB at $DB"
makeblastdb -in "$FASTA" -dbtype prot -out "$DB" -title BAHD_ref_prot_db

OUT_TAB="$OUTDIR/BAHD_ref_protein_self.tab"
OUT_TXT="$OUTDIR/BAHD_ref_protein_self.txt"
TMP_OUT="$OUTDIR/BAHD_ref_protein_self.tmp"

# Define the outfmt fields and header (tab-separated)
FIELDS=(qseqid sseqid pident length mismatch gapopen qstart qend sstart send evalue bitscore)
HEADER=$(printf "%s\t" "${FIELDS[@]}" | sed 's/\t$//')

echo -e "$HEADER" > "$OUT_TAB"

echo "[INFO] Running blastp (self-alignment). This may take some time depending on file size and threads."
blastp -query "$FASTA" -db "$DB" -outfmt "6 ${FIELDS[*]}" -evalue "$EVALUE" -num_threads "$THREADS" -max_target_seqs "$MAX_TARGET_SEQS" > "$TMP_OUT"

echo "[INFO] Appending results to $OUT_TAB"
cat "$TMP_OUT" >> "$OUT_TAB"

# Also save a human-readable copy (same contents) as .txt for convenience
cp -f "$OUT_TAB" "$OUT_TXT"

rm -f "$TMP_OUT"

echo "[DONE] Outputs written:"
echo "  - $OUT_TAB"
echo "  - $OUT_TXT"

exit 0
