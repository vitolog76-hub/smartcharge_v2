import 'package:flutter/material.dart';

class SavingProgressDialog extends StatelessWidget {
  final int progress;
  final String step;
  final String? error;
  final bool isComplete;
  final VoidCallback? onRetry;
  final VoidCallback? onViewHistory;
  final VoidCallback? onClose;

  const SavingProgressDialog({
    super.key,
    required this.progress,
    required this.step,
    this.error,
    this.isComplete = false,
    this.onRetry,
    this.onViewHistory,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: error != null 
                ? Colors.red.withOpacity(0.5)
                : isComplete 
                    ? Colors.green.withOpacity(0.5)
                    : Colors.cyanAccent.withOpacity(0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: error != null
                  ? Colors.red.withOpacity(0.2)
                  : isComplete
                      ? Colors.green.withOpacity(0.2)
                      : Colors.cyanAccent.withOpacity(0.2),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icona animata
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _buildIcon(),
            ),
            
            const SizedBox(height: 20),
            
            // Titolo
            Text(
              _getTitle(),
              style: TextStyle(
                color: _getColor(),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Progress Bar
            if (error == null && !isComplete) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: progress / 100,
                  minHeight: 8,
                  backgroundColor: Colors.grey[800],
                  valueColor: AlwaysStoppedAnimation<Color>(_getColor()),
                ),
              ),
              const SizedBox(height: 12),
              
              // Step corrente e percentuale
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    step,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    "$progress%",
                    style: TextStyle(
                      color: _getColor(),
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
            
            // Messaggio di errore
            if (error != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Text(
                  error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ),
            ],
            
            // Riepilogo successo
            if (isComplete && error == null) ...[
              const SizedBox(height: 16),
              const Text(
                "✅ Ricarica salvata con successo!",
                style: TextStyle(color: Colors.green, fontSize: 14),
              ),
            ],
            
            const SizedBox(height: 20),
            
            // Pulsanti azione
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (error != null && onRetry != null)
                  ElevatedButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text("Riprova"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                  ),
                
                if (isComplete && onViewHistory != null)
                  ElevatedButton.icon(
                    onPressed: onViewHistory,
                    icon: const Icon(Icons.history, size: 18),
                    label: const Text("Vedi Storico"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                
                if (error != null || isComplete)
                  const SizedBox(width: 8),
                
                TextButton(
                  onPressed: onClose ?? () => Navigator.of(context).pop(),
                  child: const Text("Chiudi"),
                ),
              ],
            ),
            
            if (error == null && !isComplete)
              const Padding(
                padding: EdgeInsets.only(top: 12),
                child: Text(
                  "Non chiudere l'app durante il salvataggio",
                  style: TextStyle(color: Colors.grey, fontSize: 11),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _getColor() {
    if (error != null) return Colors.red;
    if (isComplete) return Colors.green;
    return Colors.cyanAccent;
  }

  String _getTitle() {
    if (error != null) return "❌ ERRORE";
    if (isComplete) return "✅ COMPLETATO!";
    return "SALVATAGGIO IN CORSO";
  }

  Widget _buildIcon() {
    if (error != null) {
      return const Icon(Icons.error_outline, color: Colors.red, size: 50);
    }
    if (isComplete) {
      return const Icon(Icons.check_circle, color: Colors.green, size: 50);
    }
    return SizedBox(
      width: 50,
      height: 50,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 50,
            height: 50,
            child: CircularProgressIndicator(
              value: progress / 100,
              strokeWidth: 3,
              backgroundColor: Colors.grey[800],
              valueColor: AlwaysStoppedAnimation<Color>(Colors.cyanAccent),
            ),
          ),
          Text(
            "$progress%",
            style: const TextStyle(
              color: Colors.cyanAccent,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}