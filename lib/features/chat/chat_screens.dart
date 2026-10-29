import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:record/record.dart';
import 'package:just_audio/just_audio.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../auth/auth_state.dart';
import 'chat_api.dart';

const _ink=Color(0xFF171717), _muted=Color(0xFF777777), _canvas=Color(0xFFF7F7F7), _line=Color(0xFFEAEAEA);
final _chatApi=ChatApi();

class ChatListScreen extends ConsumerStatefulWidget { const ChatListScreen({super.key}); @override ConsumerState<ChatListScreen> createState()=>_ChatListScreenState(); }
class _ChatListScreenState extends ConsumerState<ChatListScreen> {
  List<Map<String,dynamic>> chats=[]; bool loading=true; String? error;
  @override void initState(){super.initState(); WidgetsBinding.instance.addPostFrameCallback((_)=>_load());}
  Future<void> _load() async { final auth=ref.read(authProvider); if(auth.isLoading){await Future<void>.delayed(const Duration(milliseconds:150));if(mounted)return _load();return;} if(!auth.isSignedIn||auth.token.isEmpty){if(mounted)context.go('/login');return;} setState(()=>loading=true); try {final result=await _chatApi.list(auth.token);if(mounted)setState(()=>chats=result); } catch(e){if(mounted)setState(()=>error=e.toString().replaceFirst('Exception: ',''));} finally{if(mounted)setState(()=>loading=false);} }
  @override Widget build(BuildContext context){final auth=ref.watch(authProvider);if(!auth.isLoading&&(!auth.isSignedIn||auth.token.isEmpty)){WidgetsBinding.instance.addPostFrameCallback((_){if(mounted)context.go('/login');});}
    return Scaffold(backgroundColor:_canvas,appBar:AppBar(title:const Text('Messages',style:TextStyle(color:_ink,fontWeight:FontWeight.w800)),backgroundColor:Colors.white,foregroundColor:_ink,elevation:0,actions:[IconButton(onPressed:_load,icon:const Icon(Icons.refresh))]),body:loading?ListView.builder(padding:const EdgeInsets.all(16),itemCount:6,itemBuilder:(_,i)=>Padding(padding:const EdgeInsets.only(bottom:12),child:Shimmer.fromColors(baseColor:const Color(0xFFEAEAEA),highlightColor:Colors.white,child:Container(height:84,decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(16)))))):error!=null?Center(child:Padding(padding:const EdgeInsets.all(24),child:Column(mainAxisSize:MainAxisSize.min,children:[Text(error!,textAlign:TextAlign.center),const SizedBox(height:12),OutlinedButton(onPressed:_load,child:const Text('Try again'))]))):chats.isEmpty?const Center(child:Padding(padding:EdgeInsets.all(28),child:Column(mainAxisSize:MainAxisSize.min,children:[Icon(Icons.chat_bubble_outline,size:48,color:_muted),SizedBox(height:14),Text('No conversations yet',style:TextStyle(fontSize:18,fontWeight:FontWeight.w800)),SizedBox(height:8),Text('Open a product and tap Message to start a conversation.',textAlign:TextAlign.center,style:TextStyle(color:_muted))]))):RefreshIndicator(onRefresh:_load,child:ListView.separated(padding:const EdgeInsets.all(16),itemCount:chats.length,separatorBuilder:(_,__)=>const SizedBox(height:10),itemBuilder:(context,index){final c=chats[index];final p=c['product'] as Map<String,dynamic>?;return Material(color:Colors.white,borderRadius:BorderRadius.circular(16),child:ListTile(shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(16),side:const BorderSide(color:_line)),leading:(p?['image_url']!=null)?ClipRRect(borderRadius:BorderRadius.circular(10),child:CachedNetworkImage(imageUrl:p!['image_url'].toString(),width:54,height:54,fit:BoxFit.cover,placeholder:(_,__)=>Shimmer.fromColors(baseColor:const Color(0xFFEAEAEA),highlightColor:Colors.white,child:Container(width:54,height:54,color:Colors.white)),errorWidget:(_,__,___)=>const Icon(Icons.shopping_bag_outlined))):const CircleAvatar(backgroundColor:_ink,child:Icon(Icons.shopping_bag_outlined,color:Colors.white)),title:Text((p?['name']??c['subject']??'Product conversation').toString(),maxLines:1,overflow:TextOverflow.ellipsis,style:const TextStyle(fontWeight:FontWeight.w800)),subtitle:Text((c['last_message']??'No messages yet').toString(),maxLines:1,overflow:TextOverflow.ellipsis),trailing:const Icon(Icons.chevron_right),onTap:()=>context.push('/chat/${c['id']}')));})));}
}

class ChatThreadScreen extends ConsumerStatefulWidget { const ChatThreadScreen({super.key,required this.chatId}); final String chatId; @override ConsumerState<ChatThreadScreen> createState()=>_ChatThreadScreenState(); }
class _ChatThreadScreenState extends ConsumerState<ChatThreadScreen>{final _text=TextEditingController();final _scroll=ScrollController();final _picker=ImagePicker();final _recorder=AudioRecorder();Map<String,dynamic>? thread;bool loading=true,sending=false,recording=false;String? error;
 @override void initState(){super.initState();WidgetsBinding.instance.addPostFrameCallback((_)=>_load());}
 Future<void> _load() async {final auth=ref.read(authProvider);if(auth.isLoading){await Future<void>.delayed(const Duration(milliseconds:150));if(mounted)return _load();return;}if(!auth.isSignedIn||auth.token.isEmpty){if(mounted)context.go('/login');return;}try{final result=await _chatApi.thread(auth.token,widget.chatId);if(mounted)setState(()=>thread=result);}catch(e){if(mounted)setState(()=>error=e.toString().replaceFirst('Exception: ',''));}finally{if(mounted)setState(()=>loading=false);}}
 Future<void> _send() async {final text=_text.text.trim();final auth=ref.read(authProvider);if(text.isEmpty||sending)return;setState(()=>sending=true);try{await _chatApi.send(auth.token,widget.chatId,text);_text.clear();await _load();}catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(e.toString().replaceFirst('Exception: ',''))));}finally{if(mounted)setState(()=>sending=false);}}
 Future<void> _uploadBytes(String name,Uint8List bytes,{String caption=''}) async {final auth=ref.read(authProvider);if(sending)return;setState(()=>sending=true);try{await _chatApi.sendAttachment(auth.token,widget.chatId,fileName:name,bytes:bytes,mimeType:'application/octet-stream',message:caption);await _load();}catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(e.toString().replaceFirst('Exception: ',''))));}finally{if(mounted)setState(()=>sending=false);}}
 Future<void> _pickImage() async {final x=await _picker.pickImage(source:ImageSource.gallery,imageQuality:85,maxWidth:1800);if(x!=null)await _uploadBytes(x.name,await x.readAsBytes());}
 Future<void> _pickVideo() async {final x=await _picker.pickVideo(source:ImageSource.gallery,maxDuration:const Duration(minutes:3));if(x!=null)await _uploadBytes(x.name,await x.readAsBytes());}
 Future<void> _pickDocument({bool audio=false}) async {final result=await FilePicker.platform.pickFiles(withData:true,type:audio?FileType.audio:FileType.custom,allowedExtensions:audio?null:['pdf','doc','docx','txt','xls','xlsx','ppt','pptx','zip']);if(result==null||result.files.isEmpty)return;final f=result.files.first;final bytes=f.bytes;if(bytes==null){if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Could not read that file. Please choose it again.')));return;}await _uploadBytes(f.name,bytes);}
 Future<void> _toggleRecording() async {try{if(!recording){if(!await _recorder.hasPermission()){if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Microphone permission is required.')));return;}await _recorder.start(const RecordConfig(encoder:AudioEncoder.aacLc),path:'mono_voice_${DateTime.now().millisecondsSinceEpoch}.m4a');if(mounted)setState(()=>recording=true);}else{final path=await _recorder.stop();if(mounted)setState(()=>recording=false);if(path!=null){final bytes=await XFile(path).readAsBytes();await _uploadBytes('voice_note.m4a',bytes);}}}catch(e){if(mounted){setState(()=>recording=false);ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Voice note error: $e')));}}}
 Future<void> _chooseAttachment() async {showModalBottomSheet<void>(context:context,showDragHandle:true,shape:const RoundedRectangleBorder(borderRadius:BorderRadius.vertical(top:Radius.circular(24))),builder:(sheet)=>SafeArea(child:Padding(padding:const EdgeInsets.all(18),child:Wrap(spacing:12,runSpacing:12,children:[_attachChoice(sheet,Icons.image_rounded,'Photo',()=>_pickImage()),_attachChoice(sheet,Icons.videocam_rounded,'Video',()=>_pickVideo()),_attachChoice(sheet,Icons.mic_rounded,'Voice note',()=>_toggleRecording()),_attachChoice(sheet,Icons.audiotrack_rounded,'Audio file',()=>_pickDocument(audio:true)),_attachChoice(sheet,Icons.description_rounded,'Document',()=>_pickDocument())]))));}
 Widget _attachChoice(BuildContext sheet,IconData icon,String label,Future<void> Function() action)=>SizedBox(width:130,child:InkWell(borderRadius:BorderRadius.circular(16),onTap:(){Navigator.pop(sheet);action();},child:Container(padding:const EdgeInsets.symmetric(vertical:18,horizontal:12),decoration:BoxDecoration(color:const Color(0xFFF7F7F7),borderRadius:BorderRadius.circular(16),border:Border.all(color:_line)),child:Column(children:[Icon(icon,size:26,color:_ink),const SizedBox(height:8),Text(label,style:const TextStyle(fontWeight:FontWeight.w700))]))));
 Widget _messageContent(Map<String,dynamic> m,bool mine){final type=(m['message_type']??'text').toString();final url=(m['attachment_url']??'').toString();final text=(m['message']??'').toString();final color=mine?Colors.white:_ink;if(url.isEmpty||type=='text')return Text(text,style:TextStyle(color:color,height:1.4));if(type=='image')return Column(crossAxisAlignment:CrossAxisAlignment.start,children:[ClipRRect(borderRadius:BorderRadius.circular(12),child:CachedNetworkImage(imageUrl:url,width:240,fit:BoxFit.cover,placeholder:(_,__)=>Shimmer.fromColors(baseColor:const Color(0xFFEAEAEA),highlightColor:Colors.white,child:Container(width:240,height:160,color:Colors.white)),errorWidget:(_,__,___)=>const Icon(Icons.broken_image_outlined,size:40))),if(text.isNotEmpty&&text!=(m['attachment_name']??''))Padding(padding:const EdgeInsets.only(top:8),child:Text(text,style:TextStyle(color:color)))]);if(type=='voice')return VoiceNotePlayer(url:url,mine:mine);final icon=type=='video'?Icons.play_circle_fill:Icons.description_rounded;final label=type=='video'?'Play video attachment':(m['attachment_name']??'Document').toString();return InkWell(onTap:()=>launchUrl(Uri.parse(url),mode:LaunchMode.externalApplication),child:Row(mainAxisSize:MainAxisSize.min,children:[Icon(icon,color:color,size:28),const SizedBox(width:9),Flexible(child:Text(label,style:TextStyle(color:color,decoration:TextDecoration.underline),maxLines:2,overflow:TextOverflow.ellipsis)),const SizedBox(width:5),Icon(Icons.open_in_new,size:14,color:color)]));}
 @override void dispose(){_text.dispose();_scroll.dispose();_recorder.dispose();super.dispose();}
 @override
 Widget build(BuildContext context) {
   final conv = thread?['conversation'] as Map<String, dynamic>?;
   final product = conv?['product'] as Map<String, dynamic>?;
   final messages = (thread?['messages'] as List? ?? const <dynamic>[])
       .whereType<Map<String, dynamic>>()
       .toList();

   return Scaffold(
     backgroundColor: _canvas,
     appBar: AppBar(
       backgroundColor: Colors.white,
       foregroundColor: _ink,
       elevation: 0,
       title: Text(
         (product?['name'] ?? conv?['subject'] ?? 'Conversation').toString(),
         maxLines: 1,
         overflow: TextOverflow.ellipsis,
         style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
       ),
       actions: [
         IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
       ],
     ),
     body: loading
         ? ListView.builder(padding:const EdgeInsets.all(16),itemCount:7,itemBuilder:(_,i)=>Padding(padding:const EdgeInsets.only(bottom:12),child:Shimmer.fromColors(baseColor:const Color(0xFFEAEAEA),highlightColor:Colors.white,child:Align(alignment:i.isEven?Alignment.centerLeft:Alignment.centerRight,child:Container(width:220,height:58,decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(16)))))))
         : error != null
             ? Center(
                 child: Column(
                   mainAxisSize: MainAxisSize.min,
                   children: [
                     Text(error!),
                     OutlinedButton(onPressed: _load, child: const Text('Retry')),
                   ],
                 ),
               )
             : Column(
                 children: [
                   if (product != null)
                     Container(
                       color: Colors.white,
                       padding: const EdgeInsets.all(12),
                       child: Row(
                         children: [
                           product['image_url'] != null ? ClipRRect(borderRadius:BorderRadius.circular(10),child:CachedNetworkImage(imageUrl:product['image_url'].toString(),width:48,height:48,fit:BoxFit.cover,placeholder:(_,__)=>Shimmer.fromColors(baseColor:const Color(0xFFEAEAEA),highlightColor:Colors.white,child:Container(width:48,height:48,color:Colors.white)),errorWidget:(_,__,___)=>const Icon(Icons.shopping_bag_outlined,size:30))) : const Icon(Icons.shopping_bag_outlined, size: 30),
                           const SizedBox(width: 12),
                           Expanded(
                             child: Column(
                               crossAxisAlignment: CrossAxisAlignment.start,
                               children: [
                                 Text(
                                   product['name']?.toString() ?? 'Product',
                                   style: const TextStyle(fontWeight: FontWeight.w800),
                                 ),
                                 if (product['price'] != null)
                                   Text(
                                     'MK ${product['price']}',
                                     style: const TextStyle(color: _muted, fontSize: 12),
                                   ),
                               ],
                             ),
                           ),
                           const Text(
                             'PRODUCT',
                             style: TextStyle(color: _muted, fontSize: 10, fontWeight: FontWeight.w800),
                           ),
                         ],
                       ),
                     ),
                   Expanded(
                     child: ListView.builder(
                       controller: _scroll,
                       padding: const EdgeInsets.all(16),
                       itemCount: messages.length,
                       itemBuilder: (context, index) {
                         final message = messages[index];
                         final mine = message['sender_type'] == 'customer';
                         return Align(
                           alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
                           child: Container(
                             margin: const EdgeInsets.only(bottom: 10),
                             padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                             constraints: const BoxConstraints(maxWidth: 330),
                             decoration: BoxDecoration(
                               color: mine ? _ink : Colors.white,
                               border: mine ? null : Border.all(color: _line),
                               borderRadius: BorderRadius.circular(16),
                             ),
                             child: _messageContent(message, mine),
                           ),
                         );
                       },
                     ),
                   ),
                   SafeArea(
                     top: false,
                     child: Container(
                       color: Colors.white,
                       padding: const EdgeInsets.all(12),
                       child: Row(
                         children: [
                           IconButton(onPressed:sending?null:_chooseAttachment,tooltip:'Attach media',icon:const Icon(Icons.add_circle_outline_rounded,color:_ink,size:27)),
                           Expanded(
                             child: TextField(
                               controller: _text,
                               maxLines: 4,
                               minLines: 1,
                               decoration: InputDecoration(
                                 hintText: 'Write a message…',
                                 filled: true,
                                 fillColor: _canvas,
                                 border: OutlineInputBorder(
                                   borderRadius: BorderRadius.circular(24),
                                   borderSide: BorderSide.none,
                                 ),
                                 contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                               ),
                               onSubmitted: (_) => _send(),
                             ),
                           ),
                           const SizedBox(width: 8),
                           IconButton(onPressed:sending?null:_toggleRecording,tooltip:recording?'Stop voice note':'Record voice note',icon:Icon(recording?Icons.stop_circle_rounded:Icons.mic_none_rounded,color:recording?Colors.red:_ink)),
                           IconButton.filled(
                             onPressed: sending ? null : _send,
                             style: IconButton.styleFrom(backgroundColor: _ink),
                             icon: sending ? const SizedBox(width:18,height:18,child:CircularProgressIndicator(strokeWidth:2,color:Colors.white)) : const Icon(Icons.send_rounded,color:Colors.white),
                           ),
                         ],
                       ),
                     ),
                   ),
                 ],
               ),
   );
 }

}

class ChatProductStartScreen extends ConsumerStatefulWidget {const ChatProductStartScreen({super.key,required this.productId,required this.product});final String productId;final Map<String,dynamic> product;@override ConsumerState<ChatProductStartScreen> createState()=>_ChatProductStartScreenState();}
class _ChatProductStartScreenState extends ConsumerState<ChatProductStartScreen>{bool starting=false;String? error;@override void initState(){super.initState();WidgetsBinding.instance.addPostFrameCallback((_)=>_start());}
 Future<void> _start()async{final auth=ref.read(authProvider);if(auth.isLoading){await Future<void>.delayed(const Duration(milliseconds:150));if(mounted)return _start();return;}if(!auth.isSignedIn||auth.token.isEmpty){if(mounted)context.go('/login');return;}setState(()=>starting=true);try{final c=await _chatApi.start(auth.token,widget.productId);if(mounted)context.go('/chat/${c['id']}');}catch(e){if(mounted)setState(()=>error=e.toString().replaceFirst('Exception: ',''));}finally{if(mounted)setState(()=>starting=false);}}
 @override Widget build(BuildContext context)=>Scaffold(backgroundColor:_canvas,appBar:AppBar(title:const Text('Starting conversation'),backgroundColor:Colors.white,foregroundColor:_ink),body:Center(child:starting?const CircularProgressIndicator():Column(mainAxisSize:MainAxisSize.min,children:[Text(error??'Unable to start this conversation.'),const SizedBox(height:12),OutlinedButton(onPressed:_start,child:const Text('Try again'))])));}


class VoiceNotePlayer extends StatefulWidget {
  const VoiceNotePlayer({super.key,required this.url,required this.mine});
  final String url; final bool mine;
  @override State<VoiceNotePlayer> createState()=>_VoiceNotePlayerState();
}
class _VoiceNotePlayerState extends State<VoiceNotePlayer> {
  late final AudioPlayer _player=AudioPlayer(); bool _loaded=false; bool _busy=false;
  @override void dispose(){_player.dispose();super.dispose();}
  Future<void> _toggle() async {if(_busy)return;setState(()=>_busy=true);try{if(_player.playing){await _player.pause();}else{if(!_loaded){await _player.setUrl(widget.url);_loaded=true;}_player.play();}}catch(_){if(mounted)ScaffoldMessenger.maybeOf(context)?.showSnackBar(const SnackBar(content:Text('Could not play this voice note.')));}finally{if(mounted)setState(()=>_busy=false);}}
  @override Widget build(BuildContext context){final c=widget.mine?Colors.white:const Color(0xFF171717);return SizedBox(width:190,child:Row(children:[IconButton(onPressed:_toggle,icon:_busy?SizedBox(width:18,height:18,child:CircularProgressIndicator(strokeWidth:2,color:c)):Icon(_player.playing?Icons.pause_circle_filled:Icons.play_circle_fill,color:c,size:32)),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,mainAxisSize:MainAxisSize.min,children:[Text('Voice note',style:TextStyle(color:c,fontWeight:FontWeight.w700)),StreamBuilder<Duration>(stream:_player.positionStream,initialData:Duration.zero,builder:(context,snapshot){final d=snapshot.data??Duration.zero;return Text('${d.inMinutes.toString().padLeft(2,'0')}:${(d.inSeconds%60).toString().padLeft(2,'0')}',style:TextStyle(color:c.withValues(alpha:.7),fontSize:11));})]))]));}
}
