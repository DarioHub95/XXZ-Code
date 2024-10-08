# !/bin/bash
set -x

# Primo istante di tempo
start_time=$(date +%s)
total_tasks=$(ls -1 "Dati_$2"/output* 2>/dev/null | wc -l)

while screen -ls | grep -q "[0-9]\+\.${2}"; do
    sleep 1
done

#-------------RICHIAMA LO SCRIPT NOTIFY_ERRORS--------------------
if [ -d "Dati_$2" ] && [ "$(ls Dati_$2 | wc -l)" -eq 2 ]; then       # Se la cartella contiene solo 2 file 
    ./scripts/notify_errors.sh 100 "[media.sh] La cartella Dati_$2 non contiene i dati di output. Eliminazione ed esco dallo screen media_$2..." 
    rm -rf "Dati_$2"
    screen -X quit
fi
#-------------RICHIAMA LO SCRIPT NOTIFY_ERRORS--------------------


# Tolleranza al 20% per il numero di -nan nei file di dati
max_nan_count=0
nstep=$(grep -oP 'int\s+nstep\s*=\s*\K\d+' main.c)
for file in "Dati_$2"/output*.txt; do
    nan_count=$(grep -c "\-nan" "$file")    

    if [ $(echo "scale=2; $nan_count / $nstep > 0.2" | bc) -eq 1 ]; then
        echo "La soglia del 20% è superata. Eliminazione del file $file..."
        rm "$file"
    else
        echo "La soglia non è superata. Nan count: $nan_count"
        if (( nan_count > max_nan_count )); then
            max_nan_count=$nan_count
        fi
    fi
done
echo "Il massimo numero di '-nan' è ${max_nan_count:-0}."

# Conta il numero di file nella cartella e salva le prime 16 righe del primo file in media totale
R_tot=$(ls -1 "Dati_$2"/output* 2>/dev/null | wc -l)
MEDIA="${3}_${2}_L${4}_R${R_tot}_$(date -u -d @$start_time +'%H.%M.%S').txt"
output_file=$(find "Dati_$2" -maxdepth 1 -type f -name "output*" | head -n 1)
head -n 16 "$output_file" > "${MEDIA}"

# Rimuovi in ogni file il numero di righe pari al massimo numero di -nan trovati 
echo "Rimuovi ${max_nan_count:-0} righe non sommabili da ogni file di output..."
for file in "Dati_$2"/output*.txt; do
    tail -n +$((max_nan_count + 16 + 1)) "$file" > "${file}.tmp" && mv "${file}.tmp" "$file"
done
echo ""

# Verifica se R_tot è maggiore del limite corrente di file aperti
if [[ $R_tot -gt $(ulimit -n) ]]; then
    ulimit -n $((R_tot + 10))  # Aumenta il limite di file aperti di R_tot + 10
    echo "Il limite dei file aperti è stato aumentato a $((R_tot + 10))"
fi


# Calcolo delle medie a 1 colonna (OPERATORE SINGOLO)
if [ "$1" -eq 2 ] || [ "$1" -eq 3 ] || [ "$1" -eq 10 ] || [ "$1" -eq 12 ]; then
echo "Media su tutte le realizzazioni..."
paste -d+ "Dati_$2"/output*.txt | awk -v R=$R_tot '{for(i=1; i<=2; i++) for(j=1; j<R; j++) $i+=$(i+j*2); printf "\t%20.15g\t%20.15g\n", $1/R, $2/R}' > "temp_output.txt"
fi

# Calcolo delle medie a 3 colonne (ENERGIE / COMPONENTI SPIN SU L)
if [[ "$1" -eq 4 || "$1" -eq 6 ]]; then
echo "Media su tutte le realizzazioni..."
paste -d+ "Dati_$2"/output*.txt | awk -v R=$R_tot '{for(i=1; i<=4; i++) for(j=1; j<R; j++) $i+=$(i+j*4); printf "\t%20.15g\t%20.15g\t%20.15g\t%20.15g\n", $1/R, $2/R, $3/R, $4/R}' > "temp_output.txt"
fi

# Calcolo delle medie a 8 colonne (CORRELAZIONE PER L=8)
if [[ "$1" -eq 5 ]]; then
echo "Media su tutte le realizzazioni..."
paste -d+ "Dati_$2"/output*.txt | awk -v R=$R_tot '{for(i=1; i<=9; i++) for(j=1; j<R; j++) $i+=$(i+j*9); printf "\t%20.15g\t%20.15g\t%20.15g\t%20.15g\t%20.15g\t%20.15g\t%20.15g\t%20.15g\t%20.15g\n", $1/R, $2/R, $3/R, $4/R, $5/R, $6/R, $7/R, $8/R, $9/R}' > "temp_output.txt"
fi

# Inserisci l'output dopo la 16esima riga
{
    head -n 16 "${MEDIA}"
    cat "temp_output.txt"
} > "${MEDIA}.tmp"

mv "${MEDIA}.tmp" "${MEDIA}"
rm temp_*.txt
echo ""

#-------------RICHIAMA LO SCRIPT NOTIFY_ERRORS--------------------
if [ $(wc -l < "${MEDIA}") -le 20 ]; then
    ./scripts/notify_errors.sh 350 "[media.sh] Il file '${MEDIA}' non contiene nessun valore medio. Uscita dallo screen media_$2..." 
    screen -X quit
if [ ! -f "${MEDIA}" ]; then
    ./scripts/notify_errors.sh 200 "[media.sh] Il file '${MEDIA}' non esiste. Uscita dallo screen media_$2..." 
    screen -X quit
fi
#-------------RICHIAMA LO SCRIPT NOTIFY_ERRORS--------------------

# Inserisci riga di Data e ora e di tasks nel file di media totale
sed -i "1i Tasks: ${R_tot}" "${MEDIA}"
sed -i "1i Date: $(date '+%Y-%m-%d %H:%M:%S')" "${MEDIA}"
sed -i '/seed/d' "${MEDIA}"

#----------------RICHIAMA LO SCRIPT NOTIFY_OK------------------------------------------
./scripts/notify_ok.sh "S" "${MEDIA}" $start_time $total_tasks
#----------------RICHIAMA LO SCRIPT NOTIFY_OK------------------------------------------

# Processa i file di output nella directory
echo "Sostituzione punti con virgole nel file delle medie..."
sed -i 's/\./,/g' "$MEDIA"

screen -X quit
