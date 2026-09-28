import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import '../widgets/climate_dialog.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();

  void _sendMessage() {
    final provider = context.read<ChatProvider>();
    final text = _controller.text;
    if (text.isNotEmpty) {
      provider.send(text);
      _controller.clear();
    }
  }

  void _showClimateDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const ClimateDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ChatProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('WeatherGPT'),
        actions: [
          DropdownButton<String>(
            value: provider.language,
            icon: const Icon(Icons.language, color: Colors.black87),
            underline: const SizedBox(),
            items: ['auto', 'English', 'Hindi', 'Telugu']
                .map((lang) => DropdownMenuItem(value: lang, child: Text(lang)))
                .toList(),
            onChanged: (val) {
              if (val != null) {
                context.read<ChatProvider>().setLanguage(val);
              }
            },
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          if (provider.hasActiveWarning)
            Container(
              padding: const EdgeInsets.all(12),
              color: Colors.red[100],
              width: double.infinity,
              child: const Row(
                children: [
                  Icon(Icons.warning, color: Colors.red),
                  SizedBox(width: 8),
                  Expanded(child: Text('Severe weather alert for your location! Check Alerts tab.', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))),
                ],
              ),
            ),
          if (provider.messages.isEmpty)
            Expanded(
              child: Center(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    ActionChip(
                      label: const Text('Weather today'),
                      onPressed: () => context.read<ChatProvider>().send('Weather today'),
                    ),
                    ActionChip(
                      label: const Text('Will it rain tomorrow?'),
                      onPressed: () => context.read<ChatProvider>().send('Will it rain tomorrow?'),
                    ),
                    ActionChip(
                      label: const Text('Any alerts near me?'),
                      onPressed: () => context.read<ChatProvider>().send('Any alerts near me?'),
                    ),
                    ActionChip(
                      label: const Text('View Climate Trends'),
                      onPressed: () => _showClimateDialog(context),
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: provider.messages.length,
                itemBuilder: (context, index) {
                  final msg = provider.messages[index];
                  if (msg.isUser) {
                    return Align(
                      alignment: Alignment.centerRight,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(msg.text, style: const TextStyle(fontSize: 16)),
                      ),
                    );
                  } else {
                    return Align(
                      alignment: Alignment.centerLeft,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(msg.text, style: const TextStyle(fontSize: 16)),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.volume_up, size: 20),
                            onPressed: () => provider.playAudio(msg.text),
                            color: Colors.blue,
                          ),
                        ],
                      ),
                    );
                  }
                },
              ),
            ),
          if (provider.loading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(),
            ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: 'Ask about the weather...',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                  color: Colors.blue,
                ),
                IconButton(
                  icon: Icon(provider.isListening ? Icons.mic : Icons.mic_none),
                  onPressed: provider.toggleListening,
                  color: provider.isListening ? Colors.red : Colors.blue,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
