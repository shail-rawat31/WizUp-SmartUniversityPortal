path = r'e:\1Wizup\1Wizup\Login Page\attendance-predictor.html'
with open(path, 'r', encoding='utf-8', errors='replace') as f:
    lines = f.readlines()

# The good new script ends at </script> on line 636 (index 635)
# We want lines 0..635 then </body> and </html>
good = lines[:636]
# Make sure it ends with </body> and </html>
tail = '\n</body>\n\n</html>\n'
result = ''.join(good) + tail
with open(path, 'w', encoding='utf-8') as f:
    f.write(result)
print(f'Done. File now has {result.count(chr(10))} lines.')
