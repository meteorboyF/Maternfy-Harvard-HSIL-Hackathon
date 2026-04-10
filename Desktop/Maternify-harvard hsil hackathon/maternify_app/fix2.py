import unicodedata

with open('lib/demo/demo_repository.dart', 'r', encoding='utf-8') as f:
    content = f.read()

idx = content.find('RED triage')
if idx != -1:
    ch = content[idx+10]
    with open('char_info.txt', 'w', encoding='utf-8') as out:
        out.write(f'Char after RED triage: {repr(ch)} hex={hex(ord(ch))} name={unicodedata.name(ch, "unknown")}\n')
        out.write(f'Context: {repr(content[idx:idx+30])}\n')

# Now do the replacements using the actual file content
# Find the exact strings
for marker, old_snippet, new_snippet in [
    ('RED triage',
     'এটি জরুরি RED triage। আপনার সর্বশেষ BP ${latest.systolicBp}/${latest.diastolicBp} mmHg এবং kick count ${latest.kickCount} হওয়ায় \'\n              \'এই উপসর্গ preeclampsia warning-এর সাথে মিলে যাচ্ছে। এখনই নিকটস্থ হাসপাতালে যান, একা থাকবেন না, এবং SOS চাপুন যাতে ক্লিনিক টিম সতর্ক হয়।',
     'এটি জরুরি অবস্থা। আপনার সর্বশেষ BP ${latest.systolicBp}/${latest.diastolicBp} mmHg এবং কিক কাউন্ট ${latest.kickCount} দেখে এই লক্ষণগুলো উদ্বেগজনক। \'\n              \'এখনই নিকটস্থ হাসপাতালে যান, একা থাকবেন না, এবং SOS চাপুন।'),
]:
    pass  # just checking

# Simpler approach: work line by line for problem lines
lines = content.split('\n')
new_lines = []
i = 0
while i < len(lines):
    line = lines[i]
    # Fix RED triage line
    if 'RED triage' in line and 'preeclampsia' not in line:
        pass  # already fixed maybe
    if 'RED triage' in line:
        new_lines.append("          'এটি জরুরি অবস্থা। আপনার সর্বশেষ BP ${latest.systolicBp}/${latest.diastolicBp} mmHg এবং কিক কাউন্ট ${latest.kickCount} দেখে এই লক্ষণগুলো উদ্বেগজনক। '")
        i += 1
        # skip the next line which has preeclampsia warning
        if i < len(lines) and 'preeclampsia' in lines[i]:
            new_lines.append("              'এখনই নিকটস্থ হাসপাতালে যান, একা থাকবেন না, এবং SOS চাপুন।',")
            i += 1
        continue
    elif 'YELLOW triage' in line:
        new_lines.append("          'আজকের লক্ষণ এবং সাম্প্রতিক রিডিং দেখে ২৪ ঘণ্টার মধ্যে ক্লিনিকে যোগাযোগ করুন। আবার BP মাপুন, বিশ্রাম নিন, এবং লক্ষণ বাড়লে জরুরি সহায়তা নিন।',")
        i += 1
        continue
    elif 'GREEN triage' in line:
        new_lines.append("          'এখনই জরুরি সংকেত দেখা যাচ্ছে না। বিশ্রাম নিন, পানি পান করুন, এবং মাথা ঘোরা, ঝাপসা দেখা, পেটব্যথা বা কিক কম হলে আবার জানান।',")
        i += 1
        continue
    elif 'Emergency request active' in line:
        new_lines.append("      statusLine: 'জরুরি অনুরোধ সক্রিয়',")
        i += 1
        continue
    elif 'ডা. ফাতেমা, ক্লিনিক ডেস্ক' in line:
        new_lines.append("          'আপনার ক্লিনিক টিম এবং জরুরি পরিচিতিকে SOS পাঠানো হয়েছে।',")
        i += 1
        continue
    elif 'সর্বশেষ BP এবং kick count' in line:
        new_lines.append("        'সর্বশেষ BP এবং কিক কাউন্ট সংযুক্ত হয়েছে',")
        i += 1
        continue
    elif 'fallback mode' in line:
        new_lines.append("        'রোগীর অবস্থান রেকর্ড করা হয়েছে',")
        i += 1
        continue
    elif 'Nusrat is now marked' in line:
        new_lines.append("        '${_motherPatient.name} উচ্চ অগ্রাধিকার রোগী হিসেবে চিহ্নিত হয়েছেন',")
        i += 1
        continue
    elif 'ভয়েস ইনপুট শোনা গেছে' in line:
        new_lines.append("        text: 'মাথা ঘুরছে আর চোখে ঝাপসা দেখছি',")
        i += 1
        continue
    else:
        new_lines.append(line)
    i += 1

result = '\n'.join(new_lines)

with open('lib/demo/demo_repository.dart', 'w', encoding='utf-8') as f:
    f.write(result)

with open('fix2_result.txt', 'w', encoding='utf-8') as f:
    f.write('Done\n')
